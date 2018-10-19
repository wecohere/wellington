# frozen_string_literal: true

# Copyright 2018 Matthew B. Gray
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

RSpec.describe ChargeCustomer do
  let(:stripe_helper) { StripeMock.create_test_helper }
  before { StripeMock.start }
  after { StripeMock.stop }

  let(:membership) { Membership.create!(name: "Clubhouse", price: 500) }
  let(:user) { create(:user) }
  let(:token) { stripe_helper.generate_card_token }

  subject(:command) { ChargeCustomer.new(membership, user, token) }

  it "creates a failed payment on card decline" do
    StripeMock.prepare_card_error(:card_declined)
    expect(command.call).to be_falsey
    expect(Charge.failed.count).to eq 1
    expect(Charge.last.stripe_id).to be_present
    expect(Charge.last.comment).to match(/Declined/i)
  end

  context "when payment succeeds" do
    before do
      expect(command.call).to be_truthy
    end

    it "creates a new successful charge" do
      expect(Charge.succeeded.count).to eq(1)
      expect(Charge.last.stripe_id).to be_present
    end

    it "is linked to our user" do
      expect(Charge.last.user).to eq user
    end
  end
end
