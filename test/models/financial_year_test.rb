# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2017 Brice Texier, David Joulin
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
# == Table: financial_years
#
#  accountant_id             :integer
#  closed                    :boolean          default(FALSE), not null
#  code                      :string           not null
#  created_at                :datetime         not null
#  creator_id                :integer
#  currency                  :string           not null
#  currency_precision        :integer
#  custom_fields             :jsonb
#  id                        :integer          not null, primary key
#  last_journal_entry_id     :integer
#  lock_version              :integer          default(0), not null
#  started_on                :date             not null
#  stopped_on                :date             not null
#  tax_declaration_frequency :string
#  tax_declaration_mode      :string           not null
#  updated_at                :datetime         not null
#  updater_id                :integer
#

require 'test_helper'

class FinancialYearTest < ActiveSupport::TestCase
  test_model_actions

  test 'chronology' do
    first_year = financial_years(:financial_years_001)
    assert_not_nil first_year

    assert_nil first_year.previous, 'No previous financial year expected'

    assert_not_nil first_year.next, "No next financial year found... #{first_year.attributes.inspect}"

    assert_not_nil first_year.next.previous
    assert_equal first_year, first_year.next.previous

    last_year = FinancialYear.order(stopped_on: :desc).first
    # Test that we can add a new financial year
    FinancialYear.create!(started_on: last_year.stopped_on + 1, stopped_on: last_year.stopped_on >> 15)

    future = Time.zone.now + 25.years
    year = FinancialYear.at(future)
    assert_not_nil year
    min = future - 1.year
    max = future + 1.year
    assert year.started_on > min, "Financial year at #{future.l} should start after #{min.l}: #{year.started_on.l}"
    assert year.stopped_on < max, "Financial year at #{future.l} should end before #{max.l}: #{year.stopped_on.l}"
  end

  test 'accountant can be set' do
    year = financial_years(:financial_years_025)
    year.accountant = create(:entity, :accountant)
    assert year.valid?
  end

  test 'cannot create exchange without accountant' do
    year = financial_years(:financial_years_025)
    refute year.can_create_exchange?
  end

  test 'cannot create exchange without journal booked by the accountant' do
    accountant = create(:entity, :accountant)
    year = financial_years(:financial_years_025)
    assert year.update_column(:accountant_id, accountant.id)
    refute year.can_create_exchange?
  end

  test 'create exchange when it has no opened exchange but journal booked by the accountant' do
    accountant = create(:entity, :accountant, :with_booked_journals)
    year = financial_years(:financial_years_025)
    assert year.update_column(:accountant_id, accountant.id)
    create(:financial_year_exchange, financial_year: year)
    assert year.can_create_exchange?
  end

  test 'cannot create exchange with opened exchanges' do
    accountant = create(:entity, :accountant, :with_booked_journals)
    year = financial_years(:financial_years_025)
    assert year.update_column(:accountant_id, accountant.id)
    create(:financial_year_exchange, :opened, financial_year: year)
    refute year.can_create_exchange?
  end

  test 'cannot change accountant with opened exchange' do
    accountant = create(:entity, :accountant, :with_booked_journals)
    year = financial_years(:financial_years_025)
    assert year.update_column(:accountant_id, accountant.id)
    create(:financial_year_exchange, :opened, financial_year: year)
    year.accountant = create(:entity, :accountant)
    refute year.valid?
  end

  test 'cannot change started_on with exchange' do
    accountant = create(:entity, :accountant, :with_booked_journals)
    year = financial_years(:financial_years_025)
    assert year.update_column(:accountant_id, accountant.id)
    create(:financial_year_exchange, :opened, financial_year: year)
    year.started_on = year.started_on + 1.day
    refute year.valid?
  end

  test 'has opened exchange with opened exchanges' do
    year = financial_years(:financial_years_025)
    accountant = create(:entity, :accountant, :with_booked_journals)
    assert year.update_column(:accountant_id, accountant.id)
    create(:financial_year_exchange, :opened, financial_year: year)
    assert year.opened_exchange?
  end

  test 'does not have opened exchange without exchange' do
    year = financial_years(:financial_years_025)
    accountant = create(:entity, :accountant, :with_booked_journals)
    assert year.update_column(:accountant_id, accountant.id)
    refute year.opened_exchange?
  end

  test 'Create years between company born at and searched year' do
    # Company born_at (in fixtures/entities.yml) is : 2015-01-06 09:00:00.000000000 Z

    searched_year = Time.now + 20.years

    searched_financial_year = FinancialYear.where('? BETWEEN started_on AND stopped_on', searched_year).order(started_on: :desc).first
    assert searched_financial_year.nil?

    year = FinancialYear.on(searched_year)
    refute year.nil?
    assert year.stopped_on.year == searched_year.year

    before_searched_year = Time.now + 19.years
    searched_financial_year = FinancialYear.where('? BETWEEN started_on AND stopped_on', before_searched_year).order(started_on: :desc).first

    refute searched_financial_year.nil?
    assert searched_financial_year.stopped_on.year == before_searched_year.year

    before_searched_year = Time.now + 10.years
    searched_financial_year = FinancialYear.where('? BETWEEN started_on AND stopped_on', before_searched_year).order(started_on: :desc).first

    refute searched_financial_year.nil?
    assert searched_financial_year.stopped_on.year == before_searched_year.year
  end

  test 'get existed year if searched year is superior to company born at' do
    # Company born_at (in fixtures/entities.yml) is : 2015-01-06 09:00:00.000000000 Z

    searched_year = Time.now + 25.years
    future_started_date = searched_year.change(month: 1)
    future_stopped_date = searched_year.change(month: 12).end_of_month

    searched_financial_year = FinancialYear.where('? BETWEEN started_on AND stopped_on', searched_year).order(started_on: :desc).first
    assert searched_financial_year.nil?

    FinancialYear.create!(started_on: future_started_date, stopped_on: future_stopped_date, currency: 'EUR')

    searched_financial_year = FinancialYear.where('? BETWEEN started_on AND stopped_on', searched_year).order(started_on: :desc).first
    refute searched_financial_year.nil?

    year = FinancialYear.on(searched_year)
    refute year.nil?
    assert year.stopped_on.year == searched_year.year
  end

  test 'financial year can t be created before company born at date' do
    assert FinancialYear.on(Date.civil(1900, 1, 4)).nil?
    assert FinancialYear.on(Date.civil(2015, 5, 4))
    assert FinancialYear.on(Date.civil(Date.today.year + 25, 5, 4))
  end

  test 'close' do
    FinancialYear.where('stopped_on < ?', Date.today).order(:started_on).each do |f|
      next if f.closed?
      # FIXME: Test is not well written. Cheating...
      journal_entries = f.journal_entries.where(state: :draft)
      journal_entries.find_each(&:confirm!) if journal_entries.any?

      assert f.closable?, "Financial year #{f.code} should be closable: " + f.closure_obstructions.to_sentence

      options = {
        forward_journal: Journal.find_by(nature: :forward, currency: f.currency) ||
                         Journal.create_one!(:forward, f.currency),
        closure_journal: Journal.find_by(nature: :closure, currency: f.currency) ||
                         Journal.create_one!(:closure, f.currency)
      }
      assert f.close(nil, options), "Financial year #{f.code} should be closed"
    end
  end
end
