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

RSpec.describe GlueSync do
  let(:supporting) { create(:membership, :supporting) }
  let(:adult) { create(:membership, :adult) }
  let(:user) { create(:user) }

  describe "#call" do
    subject(:call) { described_class.new(user).call }

    it { is_expected.to be_kind_of(Hash) }

    it "has the user's id" do
      expect(call[:id]).to eq(user.id.to_s)
      expect(call[:id]).to be_kind_of(String) # always be careful with types of IDs
    end

    it "doesn't give the user a name" do
      expect(call[:name]).to be_blank
      expect(call[:display_name]).to be_blank
    end

    it "has no roles" do
      expect(call[:roles]).to be_empty
    end

    it "doesn't add roles for supporting memberships" do
      create(:reservation, membership: supporting, user: user)
      expect(call[:roles]).to be_empty
    end

    it "doesn't add roles for unpaid attending memberships" do
      create(:reservation, :instalment, membership: adult, user: user)
      expect(call[:roles]).to be_empty
    end

    context "with paid attending membership" do
      before { create(:reservation, membership: adult, user: user) }

      it "includes the video role" do
        expect(call[:roles]).to include("video")
      end
    end
  end
end
