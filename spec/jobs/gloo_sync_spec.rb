# Copyright 2020 Matthew B. Gray
# Copyright 2020 Steven Ensslen
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

RSpec.describe GlooSync, type: :job do
  subject(:job) { described_class.new }
  let(:user) { create(:user) }

  describe "#perform" do
    it "calls save for the user" do
      expect(GlooContact).to receive(:new).with(user)
        .and_return(instance_double(GlooContact, :save! => true))

      described_class.new.perform(user.email)
    end
  end
end
