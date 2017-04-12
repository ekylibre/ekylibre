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
# == Table: journal_entries
#
#  absolute_credit            :decimal(19, 4)   default(0.0), not null
#  absolute_currency          :string           not null
#  absolute_debit             :decimal(19, 4)   default(0.0), not null
#  balance                    :decimal(19, 4)   default(0.0), not null
#  created_at                 :datetime         not null
#  creator_id                 :integer
#  credit                     :decimal(19, 4)   default(0.0), not null
#  currency                   :string           not null
#  debit                      :decimal(19, 4)   default(0.0), not null
#  financial_year_exchange_id :integer
#  financial_year_id          :integer
#  id                         :integer          not null, primary key
#  journal_id                 :integer          not null
#  lock_version               :integer          default(0), not null
#  number                     :string           not null
#  printed_on                 :date             not null
#  real_balance               :decimal(19, 4)   default(0.0), not null
#  real_credit                :decimal(19, 4)   default(0.0), not null
#  real_currency              :string           not null
#  real_currency_rate         :decimal(19, 10)  default(0.0), not null
#  real_debit                 :decimal(19, 4)   default(0.0), not null
#  resource_id                :integer
#  resource_prism             :string
#  resource_type              :string
#  state                      :string           not null
#  updated_at                 :datetime         not null
#  updater_id                 :integer
#

require 'test_helper'

class JournalEntryTest < ActiveSupport::TestCase
  test_model_actions
  test 'a journal forbids to write records before its closure date' do
    journal = journals(:journals_001)
    assert_raise ActiveRecord::RecordInvalid do
      record = journal.entries.create!(
        printed_on: journal.closed_on - 10,
        items: fake_items
      )
    end
    assert_nothing_raised do
      record = journal.entries.create!(
        printed_on: journal.closed_on + 1,
        items: fake_items
      )
    end
  end

  test 'save' do
    journal = Journal.first
    assert journal
    assert journal.valid?

    assert_raise ActiveRecord::RecordInvalid do
      JournalEntry.create!(journal: journal)
    end

    entry = JournalEntry.new(journal: journal, printed_on: Date.today, items: fake_items)
    assert entry.valid?, entry.inspect + "\n" + entry.errors.full_messages.to_sentence

    entry = journal.entries.new(printed_on: Date.today, items: fake_items)
    assert entry.valid?, entry.inspect + "\n" + entry.errors.full_messages.to_sentence

    Preference.set!(:currency, 'INR')
    assert_raise JournalEntry::IncompatibleCurrencies do
      JournalEntry.create!(journal: journal, printed_on: Date.today)
    end
  end

  test 'save with items and currency' do
    journal = Journal.find_or_create_by!(name: 'Wouhou', currency: 'BTN', nature: :various)
    journal_entry = JournalEntry.create!(
      journal: journal,
      printed_on: Date.civil(2016, 11, 14),
      real_currency_rate: 12.2565237,
      items_attributes: {
        '0' => {
          name: 'Insurance care',
          account: Account.find_or_create_by_number('41123456'),
          real_credit: 4500
        },
        '1' => {
          name: 'Insurance care',
          account: Account.find_or_create_by_number('44123456'),
          real_debit: 112.89
        },
        '2' => {
          name: 'Insurance care',
          account: Account.find_or_create_by_number('60123456'),
          real_debit: 2578.23
        },
        '3' => {
          name: 'Insurance care',
          account: Account.find_or_create_by_number('61123456'),
          real_debit: 1808.88
        }
      }
    )
    assert journal_entry.balanced?
    assert_equal 4, journal_entry.items.count

    assert_equal 55_154.36, journal_entry.items.find_by(real_credit: 4500).credit
    assert_equal 1383.64, journal_entry.items.find_by(real_debit: 112.89).debit

    assert_equal 55_154.36, journal_entry.items.find_by(real_credit: 4500).absolute_credit
    assert_equal 1383.64, journal_entry.items.find_by(real_debit: 112.89).absolute_debit

    assert_equal 4500, journal_entry.real_credit
    assert_equal 4500, journal_entry.real_debit

    assert_equal 55_154.36, journal_entry.credit
    assert_equal 55_154.36, journal_entry.debit

    assert_equal 55_154.36, journal_entry.absolute_credit
    assert_equal 55_154.36, journal_entry.absolute_debit
  end

  test 'save with items' do
    journal_entry = JournalEntry.create!(
      journal: Journal.find_by(nature: :various, currency: 'EUR'),
      printed_on: Date.today - 200,
      items_attributes: {
        '0' => {
          name: 'Insurance care',
          account: Account.find_or_create_by_number('41123456'),
          real_credit: 4500
        },
        '1' => {
          name: 'Insurance care',
          account: Account.find_or_create_by_number('44123456'),
          real_debit: 112.89
        },
        '2' => {
          name: 'Insurance care',
          account: Account.find_or_create_by_number('60123456'),
          real_debit: 2578.23
        },
        '3' => {
          name: 'Insurance care',
          account: Account.find_or_create_by_number('61123456'),
          real_debit: 1808.88
        }
      }
    )
    assert journal_entry.balanced?
    assert_equal 4, journal_entry.items.count
  end

  test 'cannot be created when in financial year exchange date range' do
    financial_year = financial_years(:financial_years_025)
    exchange = create(:financial_year_exchange, financial_year: financial_year)
    journal = create(:journal)
    entry = JournalEntry.new(journal: journal, printed_on: exchange.stopped_on + 1.day, items: fake_items)
    assert entry.valid?
    entry.printed_on = exchange.started_on + 1.day
    refute entry.valid?
  end

  test 'cannot be updated to a date in financial year exchange date range' do
    financial_year = financial_years(:financial_years_025)
    exchange = create(:financial_year_exchange, financial_year: financial_year)
    entry = create(:journal_entry, printed_on: exchange.stopped_on + 1.day, items: fake_items)
    assert entry.valid?
    entry.printed_on = exchange.started_on + 1.day
    refute entry.valid?
  end

  def fake_items(options = {})
    amount = options[:amount] || (500 * rand + 1).round(2)
    name = options[:name] || 'Lorem ipsum dolor sit amet, consectetur adipiscing elit'
    [
      JournalEntryItem.new(account: Account.first, real_debit: amount, real_credit: 0, name: name),
      JournalEntryItem.new(account: Account.second, real_debit: 0, real_credit: amount, name: name)
    ]
  end
end
