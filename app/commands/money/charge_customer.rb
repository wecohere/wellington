# frozen_string_literal: true

# Copyright 2019 Matthew B. Gray
# Copyright 2019 AJ Esler
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Money::ChargeCustomer creates a charge record against a User for the Stripe integrations
# Truthy returns mean the charge succeeded, otherwise check #errors for failure details.
class Money::ChargeCustomer
  attr_reader :reservation, :user, :token, :charge_amount, :charge, :amount_owed

  def initialize(reservation, user, token, amount_owed, charge_amount: nil)
    @reservation = reservation
    @user = user
    @token = token
    @charge_amount = charge_amount || amount_owed
    @amount_owed = amount_owed
  end

  def call
    @charge = ::Charge.stripe.pending.create!(
      user: user,
      reservation: reservation,
      stripe_id: token,
      amount: charge_amount,
      comment: "Pending stripe payment"
    )

    check_charge_amount
    setup_stripe_customer unless errors.any?
    create_stripe_charge unless errors.any?

    if errors.any?
      @charge.state = ::Charge::STATE_FAILED
      @charge.comment = error_message
    elsif !@stripe_charge[:paid]
      @charge.state = ::Charge::STATE_FAILED
    else
      @charge.state = ::Charge::STATE_SUCCESSFUL
    end

    if @stripe_charge.present?
      @charge.stripe_id       = @stripe_charge[:id]
      @charge.amount_cents    = @stripe_charge[:amount]
      @charge.comment         = @stripe_charge[:description]
      @charge.stripe_response = json_to_hash(@stripe_charge.to_json)
    end

    reservation.transaction do
      @charge.comment = ChargeDescription.new(@charge).for_users
      @charge.save!
      if fully_paid?
        reservation.update!(state: Reservation::PAID)
      else
        reservation.update!(state: Reservation::INSTALMENT)
      end
    end

    @charge.successful?
  end

  def error_message
    errors.to_sentence
  end

  def errors
    @errors ||= []
  end

  private

  def check_charge_amount
    if !charge_amount.present?
      errors << "charge amount is missing"
    end
    if charge_amount <= 0
      errors << "amount must be more than 0 cents"
    end
    if charge_amount > amount_owed
      errors << "refusing to overpay for reservation"
    end
  end

  def setup_stripe_customer
    if !user.stripe_id.present?
      stripe_customer = Stripe::Customer.create(email: user.email)
      user.update!(stripe_id: stripe_customer.id)
    end
    card_response = Stripe::Customer.create_source(user.stripe_id, source: token)
    @card_id = card_response.id
  rescue Stripe::StripeError => e
    errors << e.message.to_s
    @charge.stripe_response = json_to_hash(e.response)
    @charge.comment = "Failed to setup customer - #{e.message}"
  end

  def create_stripe_charge
    # Note, stripe does everything in cents
    @stripe_charge = Stripe::Charge.create(
      description: ChargeDescription.new(@charge).for_accounts,
      currency: $currency,
      customer: user.stripe_id,
      source: @card_id,
      amount: charge_amount.cents,
    )
  rescue Stripe::StripeError => e
    errors << e.message
    @charge.stripe_response = json_to_hash(e.response)
    @charge.comment =  "failed to create Stripe::Charge - #{e.message}"
  end

  def json_to_hash(obj)
    JSON.parse(obj.to_json)
  rescue
    {}
  end

  def fully_paid?
    @charge.successful? && (amount_owed - charge_amount) <= 0
  end
end
