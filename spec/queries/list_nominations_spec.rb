# frozen_string_literal: true

# Copyright 2019 Matthew B. Gray
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

RSpec.describe ListNominations do
  let(:reservation) { create(:reservation) }
  subject(:service) { described_class.new(reservation) }

  it { is_expected.to_not be_nil }

  context "when disabled" do
    let(:reservation) { create(:reservation, :disabled) }

    it "won't list nominations" do
      expect(service.call).to be_falsey
      expect(service.errors).to_not be_empty
    end
  end

  context "when in instalment" do
    let(:reservation) { create(:reservation, :instalment) }

    it "won't list nominations" do
      expect(service.call).to be_falsey
      expect(service.errors).to_not be_empty
    end
  end
end
