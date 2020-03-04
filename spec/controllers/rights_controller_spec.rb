# frozen_string_literal: true

# Copyright 2020 Matthew B. Gray
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

require "rails_helper"

RSpec.describe RightsController, type: :controller do
  render_views

  let(:reservation) { create(:reservation, :with_user, :with_order_against_membership) }
  let(:support) { create(:support) }

  describe "#create" do
    subject(:post_create) do
      post(:create, params: {
        reservation_id: reservation.id,
      })
    end

    before { sign_in support }

    it { is_expected.to redirect_to(reservation_path(reservation)) }

    it "disables rights when run" do
      expect { post_create }.to change { reservation.reload.disabled? }.to(true)
    end

    context "when membership rights are disabled" do
      before { reservation.update!(state: Reservation::DISABLED) }

      let(:membership_price) { reservation.membership.price }
      let(:almost_paid) { membership_price - Money.new(1) }

      it "enables rights when disabled" do
        expect { post_create }.to change { reservation.reload.disabled? }.to(false)
      end

      it "sets to instalment membership is not paid off" do
        reservation.charges.destroy_all
        create(:charge, user: reservation.user, reservation: reservation, amount: almost_paid)
        expect { post_create }.to change { reservation.reload.instalment? }.to(true)
      end

      it "sets to paid when membership is paid off" do
        expect { post_create }.to change { reservation.reload.paid? }.to(true)
      end
    end
  end
end
