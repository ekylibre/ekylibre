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
# == Table: journal_entries
#
#  absolute_credit            :decimal(19, 4)   default(0.0), not null
#  absolute_currency          :string           not null
#  absolute_debit             :decimal(19, 4)   default(0.0), not null
#  balance                    :decimal(19, 4)   default(0.0), not null
#  continuous_number          :integer
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
#  reference_number           :string
#  resource_id                :integer
#  resource_prism             :string
#  resource_type              :string
#  state                      :string           not null
#  updated_at                 :datetime         not null
#  updater_id                 :integer
#  validated_at               :datetime
#

require 'test_helper'

class JournalEntryTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions
  test 'a journal forbids to write records before its closure date' do
    journal = journals(:journals_001)
    assert_raise ActiveRecord::RecordInvalid do
      journal.entries.create!(
        printed_on: journal.closed_on - 10,
        items: fake_items
      )
    end
    assert_nothing_raised do
      journal.entries.create!(
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

    entry = JournalEntry.new(journal: journal, printed_on: Date.new(2018, 1, 1), items: fake_items)
    assert entry.valid?, entry.inspect + "\n" + entry.errors.full_messages.to_sentence

    entry = journal.entries.new(printed_on: Date.new(2018, 1, 1), items: fake_items)
    assert entry.valid?, entry.inspect + "\n" + entry.errors.full_messages.to_sentence

    Preference.set!(:currency, 'INR')
    assert_raise JournalEntry::IncompatibleCurrencies do
      JournalEntry.create!(journal: journal, printed_on: Date.new(2018, 1, 1))
    end
  end

  test 'save with items and currency' do
    journal = Journal.find_or_create_by!(nature: :various)
    journal.update! name: 'Wouhou', currency: 'BTN'
    journal_entry = JournalEntry.create!(
      journal: journal,
      printed_on: Date.civil(2016, 11, 14),
      real_currency_rate: 12.2565237,
      items_attributes: {
        '0' => {
          name: 'Insurance care',
          account: Account.find_or_create_by_number('42123456'),
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
          account: Account.find_or_create_by_number('42123456'),
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

  test 'items are updated with entry' do
    journal_entry = JournalEntry.create!(
      journal: Journal.find_by(nature: :various, currency: 'EUR'),
      printed_on: Date.today - 200,
      items_attributes: {
        '0' => {
          name: 'Insurance care',
          account: Account.find_or_create_by_number('42123456'),
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

    journal_entry.journal.update(currency: 'USD')
    journal_entry.update(real_currency: 'USD', number: 'HELLO', real_currency_rate: 0.5)
    item_attributes = journal_entry.items
                        .pluck(:entry_number, :real_currency, :real_currency_rate)
                        .map { |att| att[0...2] + [att.last.to_f] }
                        .uniq
                        .first
    assert_equal ['HELLO', 'USD', 0.5], item_attributes

    journal_entry.update_columns(real_currency: 'EUR', number: 'is it me you\'re looking for?', real_currency_rate: 1.0)
    item_attributes = journal_entry.items
                        .pluck(:entry_number, :real_currency, :real_currency_rate)
                        .map { |att| att[0...2] + [att.last.to_f] }
                        .uniq
                        .first
    assert_equal ['is it me you\'re looking for?', 'EUR', 1.0], item_attributes
  end

  test 'cannot be created when in opened financial year exchange date range' do
    financial_year = financial_years(:financial_years_025)
    exchange = create(:financial_year_exchange, :opened, financial_year: financial_year)
    journal = create(:journal)
    entry = JournalEntry.new(journal: journal, printed_on: exchange.stopped_on + 1.day, items: fake_items)
    assert entry.valid?
    entry.printed_on = exchange.started_on + 1.day
    refute entry.valid?
  end

  test 'can be created when in closed financial year exchange date range' do
    financial_year = financial_years(:financial_years_025)
    exchange = create(:financial_year_exchange, financial_year: financial_year)
    journal = create(:journal)
    entry = JournalEntry.new(journal: journal, printed_on: exchange.stopped_on + 1.day, items: fake_items)
    assert entry.valid?
    entry.printed_on = exchange.started_on + 1.day
    assert entry.valid?
  end

  test 'cannot be updated to a date in opened financial year exchange date range' do
    financial_year = financial_years(:financial_years_025)
    exchange = create(:financial_year_exchange, :opened, financial_year: financial_year)
    entry = create(:journal_entry, printed_on: exchange.stopped_on + 1.day, items: fake_items)
    assert entry.valid?
    entry.printed_on = exchange.started_on + 1.day
    refute entry.valid?
  end

  test 'can be updated to a date in closed financial year exchange date range' do
    financial_year = financial_years(:financial_years_025)
    exchange = create(:financial_year_exchange, financial_year: financial_year)
    exchange.close!
    entry = create(:journal_entry, printed_on: exchange.stopped_on + 1.day, items: fake_items)
    assert entry.valid?
    entry.printed_on = exchange.started_on + 1.day
    assert entry.valid?
  end

  test 'can be closed when confirmed' do
    entry = create(:journal_entry, state: :confirmed, items: fake_items)
    assert entry.close
    assert_equal :closed, entry.state_name
  end

  test 'confirm set the validated at' do
    entry = create(:journal_entry, state: :draft, items: fake_items)
    entry.confirm
    assert entry.reload.validated_at
  end

  test 'editable when draft' do
    entry = create(:journal_entry, state: :draft, items: fake_items)
    assert entry.editable?
  end

  test 'not editable when confirmed' do
    entry = create(:journal_entry, state: :confirmed, items: fake_items)
    assert_not entry.editable?
  end

  test 'not editable when closed' do
    entry = create(:journal_entry, state: :closed, items: fake_items)
    assert_not entry.editable?
  end

  test 'updateable when draft' do
    entry = create(:journal_entry, state: :draft, items: fake_items)
    assert entry.updateable?
  end

  test 'updateable when confirmed' do # needed to support :confirm event
    entry = create(:journal_entry, state: :confirmed, items: fake_items)
    assert entry.updateable?
  end

  test 'not updateable when closed' do
    entry = create(:journal_entry, state: :closed, items: fake_items)
    assert_not entry.updateable?
  end

  test 'destroyable when draft' do
    entry = create(:journal_entry, state: :draft, items: fake_items)
    assert entry.destroyable?
  end

  test 'can be destroyed when draft' do
    entry = create(:journal_entry, state: :draft, items: fake_items)
    entry.destroy
    assert entry.destroyed?
  end

  test 'not destroyable when confirmed' do
    entry = create(:journal_entry, state: :confirmed, items: fake_items)
    assert_not entry.destroyable?
  end

  test 'not destroyable when closed' do
    entry = create(:journal_entry, state: :closed, items: fake_items)
    assert_not entry.destroyable?
  end

  test 'raises on update when confirmed' do
    entry = create(:journal_entry, state: :confirmed, items: fake_items)
    assert_raises(Ekylibre::Record::RecordNotUpdateable) do
      entry.update_attribute(:number, 123_123_123)
    end
  end

  test 'raises on update when closed' do
    entry = create(:journal_entry, state: :closed, items: fake_items)
    assert_raises(Ekylibre::Record::RecordNotUpdateable) do
      entry.update_attribute(:number, 123_123_123)
    end
  end

  test 'raises on destroy when confirmed' do
    entry = create(:journal_entry, state: :confirmed, items: fake_items)
    assert_raises(Ekylibre::Record::RecordNotDestroyable) do
      entry.destroy
    end
  end

  test 'raises on destroy when closed' do
    entry = create(:journal_entry, state: :closed, items: fake_items)
    assert_raises(Ekylibre::Record::RecordNotDestroyable) do
      entry.destroy
    end
  end

  test "reference_number refers to resource's reference number" do
    sale = create(:sale, invoiced_at: DateTime.new(2018, 1, 1))
    sale_item = create(:sale_item, sale: sale)
    sale.propose
    sale.invoice
    journal_entry = JournalEntry.where(resource_id: sale.id, resource_type: 'Sale').first
    assert_equal sale.number, journal_entry.reference_number
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
