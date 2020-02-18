# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: financial_year_exchanges
#
#  closed_at                :datetime
#  created_at               :datetime         not null
#  creator_id               :integer
#  financial_year_id        :integer          not null
#  id                       :integer          not null, primary key
#  import_file_content_type :string
#  import_file_file_name    :string
#  import_file_file_size    :integer
#  import_file_updated_at   :datetime
#  lock_version             :integer          default(0), not null
#  public_token             :string
#  public_token_expired_at  :datetime
#  started_on               :date             not null
#  stopped_on               :date             not null
#  updated_at               :datetime         not null
#  updater_id               :integer
#
require 'test_helper'

class FinancialYearExchangeTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  test 'opened scope includes opened exchanges' do
    financial_year = financial_years(:financial_years_025)
    exchange = create(:financial_year_exchange, :opened, financial_year: financial_year)
    assert FinancialYearExchange.opened.pluck(:id).include?(exchange.id)
  end

  test 'opened scope does not include closed exchanges' do
    financial_year = financial_years(:financial_years_025)
    exchange = create(:financial_year_exchange, financial_year: financial_year)
    refute FinancialYearExchange.opened.pluck(:id).include?(exchange.id)
  end

  test 'closed scope includes closed exchanges' do
    financial_year = financial_years(:financial_years_025)
    exchange = create(:financial_year_exchange, financial_year: financial_year)
    assert FinancialYearExchange.closed.pluck(:id).include?(exchange.id)
  end

  test 'closed scope does not include opened exchanges' do
    financial_year = financial_years(:financial_years_025)
    exchange = create(:financial_year_exchange, :opened, financial_year: financial_year)
    refute FinancialYearExchange.closed.pluck(:id).include?(exchange.id)
  end

  test 'for_public_token returns the exchange when the token is not expired' do
    financial_year = financial_years(:financial_years_025)
    exchange = create(:financial_year_exchange, :opened, financial_year: financial_year, public_token: '123ABC', public_token_expired_at: Time.zone.today + 1.day)
    assert_equal exchange, FinancialYearExchange.for_public_token('123ABC')
  end

  test 'for_public_token raises when the token is expired' do
    financial_year = financial_years(:financial_years_025)
    exchange = create(:financial_year_exchange, :opened, financial_year: financial_year, public_token: '123ABC', public_token_expired_at: Time.zone.today - 1.day)
    assert_raises(ActiveRecord::RecordNotFound) do
      FinancialYearExchange.for_public_token(exchange.public_token)
    end
  end

  test 'is valid' do
    financial_year = financial_years(:financial_years_025)
    exchange = build(:financial_year_exchange, financial_year: financial_year)
    assert exchange.valid?
  end

  # test 'initialize with stopped on set to yesterday' do
  #   yesterday = Time.zone.yesterday
  #   exchange = FinancialYearExchange.new
  #   assert_equal yesterday, exchange.stopped_on
  # end

  test 'does not initialize with stopped on set to yesterday when stopped on is filled' do
    today = Time.zone.today
    exchange = FinancialYearExchange.new(stopped_on: today)
    assert_equal today, exchange.stopped_on
  end

  test 'needs a stopped on' do
    financial_year = financial_years(:financial_years_025)
    exchange = build(:financial_year_exchange, financial_year: financial_year)
    exchange.stopped_on = nil
    refute exchange.valid?
  end

  test 'stopped on is before financial year stopped on' do
    financial_year = financial_years(:financial_years_025)
    exchange = build(:financial_year_exchange, financial_year: financial_year)
    exchange.stopped_on = exchange.financial_year.stopped_on + 1.day
    refute exchange.valid?
  end

  test 'needs a financial year' do
    financial_year = financial_years(:financial_years_025)
    exchange = build(:financial_year_exchange, financial_year: financial_year)
    exchange.financial_year = nil
    refute exchange.valid?
  end

  test 'started on is set before create validations' do
    financial_year = financial_years(:financial_years_025)
    exchange = FinancialYearExchange.new(financial_year: financial_year)
    refute exchange.started_on.present?
    exchange.valid?
    assert exchange.started_on.present?
  end

  test 'generates public token' do
    financial_year = financial_years(:financial_years_025)
    exchange = build(:financial_year_exchange, financial_year: financial_year)
    refute exchange.public_token.present?
    exchange.generate_public_token!
    assert exchange.public_token.present?
  end

  test 'public token expires on is set to 1 month later' do
    financial_year = financial_years(:financial_years_025)
    exchange = build(:financial_year_exchange, financial_year: financial_year)
    exchange.generate_public_token!
    assert exchange.public_token_expired_at.present?
    assert_equal Time.zone.today + 1.month, exchange.public_token_expired_at
  end

  test 'started on is not updated on update' do
    financial_year = financial_years(:financial_years_025)
    exchange = build(:financial_year_exchange, financial_year: financial_year)
    initial_started_on = exchange.started_on
    exchange.closed_at = Time.zone.now
    assert exchange.save
    assert_equal initial_started_on, exchange.started_on
  end

  test 'started on is the financial year started on when the financial year has no other exchange' do
    financial_year = financial_years(:financial_years_025)
    exchange = FinancialYearExchange.new(financial_year: financial_year)
    assert_equal financial_year.started_on, get_computed_started_on(exchange)
  end

  test 'started on is the latest financial year exchange stopped on when the financial year has other exchanges' do
    financial_year = financial_years(:financial_years_025)
    previous_exchange = create(:financial_year_exchange, financial_year: financial_year)
    exchange = FinancialYearExchange.new(financial_year: financial_year)
    assert_equal previous_exchange.stopped_on, get_computed_started_on(exchange), 'Expected start date of exchange is not encountered. Financial year started on ' + financial_year.started_on.l(locale: :eng) + ' and stopped on ' + financial_year.stopped_on.l(locale: :eng) + ' and previous exchange stopped on ' + exchange.stopped_on.l(locale: :eng)
  end

  test 'create closes journal entries from non-booked journal between financial year start and exchange lock when the financial year has no other exchange' do
    financial_year = financial_years(:financial_years_025)
    stopped_on = financial_year.stopped_on - 2.days

    journal = create(:journal, accountant_id: nil)
    draft_entries = create_list(:journal_entry, 2, :with_items, journal: journal, printed_on: financial_year.started_on + 1.day)
    confirmed_entries = create_list(:journal_entry, 2, :confirmed, :with_items, journal: journal, printed_on: financial_year.started_on + 1.day)

    exchange = FinancialYearExchange.new(financial_year: financial_year, stopped_on: stopped_on)
    assert exchange.save

    draft_entries.each(&:reload)
    confirmed_entries.each(&:reload)

    assert draft_entries.all?(&:closed?)
    assert confirmed_entries.all?(&:closed?)
    assert draft_entries.all? { |e| e.financial_year_exchange_id == exchange.id }
    assert confirmed_entries.all? { |e| e.financial_year_exchange_id == exchange.id }
  end

  test 'create does not close journal entries from journals booked by the financial year accountant' do
    accountant = create(:entity, :accountant)
    financial_year = financial_years(:financial_years_025)
    assert financial_year.update_column(:accountant_id, accountant.id)

    stopped_on = financial_year.stopped_on - 2.days

    journal = create(:journal, accountant_id: accountant.id)
    draft_entries = create_list(:journal_entry, 2, :with_items, journal: journal, printed_on: financial_year.started_on + 1.day)

    exchange = FinancialYearExchange.new(financial_year: financial_year, stopped_on: stopped_on)
    assert exchange.save
    assert draft_entries.all? { |e| e.reload.draft? }
  end

  test 'create does not close journal entries not between financial year start and exchange lock when the financial year has no other exchange' do
    financial_year = financial_years(:financial_years_025)
    stopped_on = financial_year.stopped_on - 2.days

    journal = create(:journal, accountant_id: nil)
    draft_entries = create_list(:journal_entry, 2, :with_items, journal: journal, printed_on: stopped_on + 1.day)
    confirmed_entries = create_list(:journal_entry, 2, :confirmed, :with_items, journal: journal, printed_on: stopped_on + 1.day)

    exchange = FinancialYearExchange.new(financial_year: financial_year, stopped_on: stopped_on)
    assert exchange.save
    assert draft_entries.all? { |e| e.reload.draft? }
    assert confirmed_entries.all? { |e| e.reload.confirmed? }
  end

  test 'create closes journal entries from non-booked journal between previous and actual exchanges lock' do
    financial_year = financial_years(:financial_years_025)
    previous_exchange = create(:financial_year_exchange, financial_year: financial_year)
    stopped_on = financial_year.stopped_on - 2.days

    journal = create(:journal, accountant_id: nil)
    draft_entries = create_list(:journal_entry, 2, :with_items, journal: journal, printed_on: previous_exchange.stopped_on + 1.day)
    confirmed_entries = create_list(:journal_entry, 2, :confirmed, :with_items, journal: journal, printed_on: previous_exchange.stopped_on + 1.day)

    exchange = FinancialYearExchange.new(financial_year: financial_year, stopped_on: stopped_on)
    assert exchange.save

    draft_entries.each(&:reload)
    confirmed_entries.each(&:reload)

    assert draft_entries.all?(&:closed?)
    assert confirmed_entries.all?(&:closed?)
    assert draft_entries.all? { |e| e.financial_year_exchange_id == exchange.id }
    assert confirmed_entries.all? { |e| e.financial_year_exchange_id == exchange.id }
  end

  test 'create does not close journal entries not between previous and actual exchanges lock' do
    financial_year = financial_years(:financial_years_025)
    stopped_on = financial_year.stopped_on - 2.days

    journal = create(:journal, accountant_id: nil)
    draft_entries = create_list(:journal_entry, 2, :with_items, journal: journal, printed_on: stopped_on + 1.day)
    confirmed_entries = create_list(:journal_entry, 2, :confirmed, :with_items, journal: journal, printed_on: stopped_on + 1.day)

    exchange = FinancialYearExchange.new(financial_year: financial_year, stopped_on: stopped_on)
    assert exchange.save
    assert draft_entries.all? { |e| e.reload.draft? }
    assert confirmed_entries.all? { |e| e.reload.confirmed? }
  end

  test 'accountant_email is the accountant default email' do
    accountant = create(:entity, :accountant, :with_email)
    financial_year = financial_years(:financial_years_025)
    assert financial_year.update_column(:accountant_id, accountant.id)
    exchange = create(:financial_year_exchange, financial_year: financial_year)
    assert_equal accountant.default_email_address.coordinate, exchange.accountant_email
  end

  test 'has accountant email when the accountant has an email' do
    accountant = create(:entity, :accountant, :with_email)
    financial_year = financial_years(:financial_years_025)
    assert financial_year.update_column(:accountant_id, accountant.id)
    exchange = create(:financial_year_exchange, :opened, financial_year: financial_year)
    accountant = exchange.accountant
    assert accountant, 'Accountant is missing'
    accountant.emails.delete_all if accountant.emails.any?
    assert exchange.accountant.emails.empty?
    refute exchange.accountant_email?
    accountant.emails.create!(coordinate: 'accountant@accounting.org')
    exchange.reload
    assert exchange.accountant_email?
  end

  test 'is opened without closed at' do
    financial_year = financial_years(:financial_years_025)
    exchange = create(:financial_year_exchange, :opened, financial_year: financial_year)
    assert exchange.closed_at.blank?
    assert exchange.opened?
  end

  test 'is not opened with closed at' do
    financial_year = financial_years(:financial_years_025)
    exchange = create(:financial_year_exchange, financial_year: financial_year)
    assert exchange.closed_at.present?
    refute exchange.opened?
  end

  test 'it closes' do
    financial_year = financial_years(:financial_years_025)
    exchange = create(:financial_year_exchange, :opened, financial_year: financial_year)
    assert exchange.close!
    assert_equal exchange.reload.closed_at.to_date, Time.zone.today
  end

  def get_computed_started_on(exchange)
    exchange.valid?
    exchange.started_on
  end

  def opened_financial_year_exchange
    exchange = FinancialYearExchange.joins(:financial_year).reorder(stopped_on: :desc).where(closed_at: nil)
                                    .where('financial_years.stopped_on != financial_year_exchanges.stopped_on').first
    unless exchange
      financial_year = FinancialYear.where('stopped_on <= ?', Time.zone.today)
                                    .where.not(stopped_on: FinancialYearExchange.where(closed_at: nil).select(:stopped_on))
                                    .order(stopped_on: :desc).first
      assert financial_year, 'Financial year is missing'
      exchange = financial_year.exchanges.create!
    end
    unless exchange.accountant
      exchange.financial_year.update_column(:accountant_id, Entity.normal.first.id)
    end
    assert exchange, 'An opened exchange is missing'
    exchange
  end
end
