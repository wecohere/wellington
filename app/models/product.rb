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

class Product < ApplicationRecord
  PRICES = {
    adult: 370_00,
    young_adult: 225_00,
    unwaged: 225_00,
    child: 105_00,
    kid_in_tow: 0,
    supporting: 75_00,
  }.with_indifferent_access.freeze

  PRESUPPORT_PRICES = {
    silver_fern: PRICES[:adult] - 50_00,
    kiwi: PRICES[:adult] - 150_00,
    tuatara: 0,
    pre_oppose: 0,
    pre_support: 0,
  }.with_indifferent_access.freeze

  validates :active_from, presence: true
  validates :category, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :level, presence: true

  has_many :orders
end
