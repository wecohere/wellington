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

Rails.application.routes.draw do
  root to: "charges#index"

  # For people who were imported from Kansa and may have an old login link
  get "/login/:email/:key", to: "user_tokens#kansa_login_link", email: /[^\/]+/, key: /[^\/]+/

  resources :charges
  resources :user_tokens, only: [:new, :show, :create], id: /[^\/]+/ do
    get :logout, on: :collection
  end

  devise_for :users
end
