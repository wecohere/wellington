# frozen_string_literal: true

# Copyright 2020 Steven Ensslen
# Copyright 2020 Victoria Garcia
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

class RankMailer < ApplicationMailer
#  include ApplicationHelper
  default from: $member_services_email

def rank_ballot(reservation)
  @detail = reservation.active_claim.contact
  @ranks = reservation.ranks.sort_by{ |rank| [rank.finalist.category.id, rank.position]}

    mail(
      subject: "Your 2021 Hugo Ballot",
      to: reservation.user.email,
      from: "Hugo Awards 2021 <hugohelp@discon3.org>"
    )
  end

  def ranks_open_chicago(user:)
    @user = user
    @reservations = user.reservations.joins(:membership).merge(Membership.can_vote)

    account_numbers = account_numbers_from(@reservations)
    if account_numbers.count == 1
      subject = "#{worldcon_public_name}: Hugo voting is now open for member #{account_numbers.first}"
    else
      subject = "#{worldcon_public_name}: Hugo voting is now open for members #{account_numbers.to_sentence}"
    end

    mail(to: user.email, from: "#{email_hugo_help}", subject: subject)
  end

  def ranks_open_conzealand(user:)
    @user = user
    @reservations = user.reservations.joins(:membership).merge(Membership.can_vote)

    account_numbers = account_numbers_from(@reservations)
    if account_numbers.count == 1
      subject = "CoNZealand: Hugo voting is now open for member #{account_numbers.first}"
    else
      subject = "CoNZealand: Hugo voting is now open for members #{account_numbers.to_sentence}"
    end

    mail(to: user.email, from: "hugohelp@conzealand.nz", subject: subject)
  end

  def ranks_reminder_2_weeks_left_conzealand(email:)
    user = User.find_by!(email: email)
    reservations_that_can_vote = user.reservations.joins(:membership).merge(Membership.can_vote)

    if reservations_that_can_vote.none?
      return
    end

    account_numbers = account_numbers_from(reservations_that_can_vote)
    if account_numbers.count == 1
      subject = "2 weeks to go! Hugo Award Voting Reminder for member #{account_numbers.first}"
    else
      subject = "2 weeks to go! Hugo Award Voting Reminder for members #{account_numbers.to_sentence}"
    end

    @details = Detail.where(claim_id: user.active_claims)

    mail(to: user.email, from: "hugohelp@conzealand.nz", subject: subject)
  end

  def ranks_reminder_2_weeks_left_dublin(email:)
    user = User.find_by!(email: email)
    reservations_that_can_vote = user.reservations.joins(:membership).merge(Membership.can_vote)

    if reservations_that_can_vote.none?
      return
    end

    account_numbers = account_numbers_from(reservations_that_can_vote)
    if account_numbers.count == 1
      subject = "2 weeks to go! Hugo Award Voting Reminder for account #{account_numbers.first}"
    else
      subject = "2 weeks to go! Hugo Award Voting Reminder for accounts #{account_numbers.to_sentence}"
    end

    @details = Detail.where(claim_id: user.active_claims)

    mail(to: user.email, from: "hugohelp@conzealand.nz", subject: subject)
  end

  # Unlike the other templates the only difference in this is the subject line, hence a single mailer
  def ranks_reminder_3_days_left(email:)

    @worldcon_greeting_init_caps = worldcon_greeting_init_caps
    @hugo_vote_deadline = hugo_vote_deadline
    @email_hugo_help = email_hugo_help
    @hugo_ballot_download_a4 = hugo_ballot_download_a4
    @hugo_ballot_download_letter = hugo_ballot_download_letter
    @wsfs_constitution_link = wsfs_constitution_link
    @worldcon_year = worldcon_year_after
    @worldcon_public_name = worldcon_public_name

    user = User.find_by!(email: email)

    if user.reservations.none?
      return
    end

    account_numbers = account_numbers_from(user.reservations)
    conzealand = conzealand_memberships.where(reservations: {id: user.reservations}).any?

    if account_numbers.count == 1 && conzealand
      subject = "Hugo Voting Closes in 3 Days! for member #{account_numbers.first}"
    elsif conzealand
      subject = "Hugo Voting Closes in 3 Days! for members #{account_numbers.to_sentence}"
    elsif account_numbers.count == 1
      subject = "Hugo Voting Closes in 3 Days! for account #{account_numbers.first}"
    else
      subject = "Hugo Voting Closes in 3 Days! for accounts #{account_numbers.to_sentence}"
    end

    @details = Detail.where(claim_id: user.active_claims)

    mail(to: user.email, from: "#{email_hugo_help}", subject: subject)
  end

  private

  # Given reservations, gets membership numbers and puts a pound in front of each
  def account_numbers_from(reservations)
    reservations.pluck(:membership_number).map { |n| "##{n}" }
  end

  def conzealand_memberships
    Membership.can_vote.where.not(name: :dublin).joins(:reservations)
  end
end
