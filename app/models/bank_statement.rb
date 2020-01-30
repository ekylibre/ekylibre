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
# == Table: bank_statements
#
#  accounted_at           :datetime
#  cash_id                :integer          not null
#  created_at             :datetime         not null
#  creator_id             :integer
#  credit                 :decimal(19, 4)   default(0.0), not null
#  currency               :string           not null
#  custom_fields          :jsonb
#  debit                  :decimal(19, 4)   default(0.0), not null
#  id                     :integer          not null, primary key
#  initial_balance_credit :decimal(19, 4)   default(0.0), not null
#  initial_balance_debit  :decimal(19, 4)   default(0.0), not null
#  journal_entry_id       :integer
#  lock_version           :integer          default(0), not null
#  number                 :string           not null
#  started_on             :date             not null
#  stopped_on             :date             not null
#  updated_at             :datetime         not null
#  updater_id             :integer
#

class BankStatement < Ekylibre::Record::Base
  include Attachable
  include Customizable
  belongs_to :cash
  belongs_to :journal_entry
  has_many :items, class_name: 'BankStatementItem', dependent: :destroy, inverse_of: :bank_statement
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :credit, :debit, :initial_balance_credit, :initial_balance_debit, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :currency, :number, presence: true, length: { maximum: 500 }
  validates :started_on, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  validates :stopped_on, presence: true, timeliness: { on_or_after: ->(bank_statement) { bank_statement.started_on || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  validates :cash, presence: true
  # ]VALIDATORS]
  validates :currency, length: { allow_nil: true, maximum: 3 }
  validates :number, uniqueness: { scope: :cash_id }

  accepts_nested_attributes_for :items, reject_if: proc { |params| params['name'].blank? && params['transfered_on'].blank? && params['debit'].to_f.zero? && params['credit'].to_f.zero? }, allow_destroy: true

  accepts_nested_attributes_for :items, allow_destroy: true

  delegate :name, :currency, :journal, :account, :account_id, :next_reconciliation_letters, to: :cash, prefix: true

  scope :find_by_date, lambda { |started_on, stopped_on, cash_id|
    find_by('started_on <= ? AND stopped_on >= ? AND cash_id = ?', started_on, stopped_on, cash_id)
  }

  scope :for_cash, ->(cash){ where(cash: cash) }

  scope :between, lambda { |started_on, stopped_on|
    start_range = where(started_on: started_on..stopped_on)
    stop_range = where(stopped_on: started_on..stopped_on)
    start_range = start_range.where_values.reduce(:and)
    stop_range = stop_range.where_values.reduce(:and)
    where(start_range.or(stop_range)).distinct
  }

  scope :on, ->(date) {
    where('? BETWEEN started_on AND stopped_on', date)
  }

  before_validation do
    self.currency = cash_currency if cash
    active_items = items.to_a.delete_if(&:marked_for_destruction?)
    self.debit  = active_items.map(&:debit).compact.sum
    self.credit = active_items.map(&:credit).compact.sum
    self.initial_balance_debit ||= 0
    self.initial_balance_credit ||= 0
  end

  # A bank account statement has to contain all the planned records.
  validate do
    if started_on && others.where('? BETWEEN started_on AND stopped_on', started_on).any?
      errors.add(:started_on, :overlap_sibling)
    end
    if stopped_on && others.where('? BETWEEN started_on AND stopped_on', stopped_on).any?
      errors.add(:stopped_on, :overlap_sibling)
    end
    if started_on && stopped_on
      if started_on > stopped_on
        errors.add(:stopped_on, :posterior, to: started_on.l)
      end
    end
    if initial_balance_debit.nonzero? && initial_balance_credit.nonzero?
      errors.add(:initial_balance_credit, :unvalid_amounts)
    end
  end

  before_save do
    changed_reconciliated_items = items.select do |item|
      reconciliated = item.letter.present?
      debit_or_credit_changed = item.credit_changed? || item.debit_changed?
      reconciliated && (debit_or_credit_changed || item.marked_for_destruction?)
    end
    reconciliated_letters_to_clear = changed_reconciliated_items.map(&:letter).uniq
    clear_reconciliation_with_letters reconciliated_letters_to_clear
  end

  bookkeep do |b|
    b.journal_entry(cash_journal, printed_on: stopped_on, if: (!cash.enable_bookkeep_bank_item_details && cash.suspend_until_reconciliation)) do |entry|
        # label = "BS #{cash.name} #{number}"
        # balance = items.sum('credit - debit')
      items.each do |item|
        entry.add_debit(item.name, cash.main_account_id, item.credit_balance, as: :bank)
        entry.add_credit(item.name, cash.suspense_account_id, item.credit_balance, as: :suspended, resource: item)
      end
      # entry.add_debit(label, cash.main_account_id, balance, as: :bank)
      # entry.add_credit(label, cash.suspense_account_id, balance, as: :suspended)
    end
  end

  def balance_credit
    (debit > credit ? 0.0 : credit - debit)
  end

  def balance_debit
    (debit > credit ? debit - credit : 0.0)
  end

  def remaining_items_to_reconcile
    if items_to_lettered = items.where(letter: nil)
      items_to_lettered.count
    else
      return 0
    end
  end

  def remaining_amount_to_reconcile
    remaining_amount = 0.0
    if items_to_lettered = items.where(letter: nil)
      items_to_lettered.each do |i|
        remaining_amount += i.credit_balance.abs
      end
    end
    remaining_amount
  end

  def siblings
    self.class.where(cash_id: cash_id)
  end

  def others
    siblings.where.not(id: id || 0)
  end

  def previous
    self.class.where('stopped_on <= ?', started_on).reorder(stopped_on: :desc).first
  end

  def next
    self.class.where('started_on >= ?', stopped_on).reorder(started_on: :asc).first
  end

  def next_letter
    cash.next_reconciliation_letter
  end

  def letter_items(statement_items, journal_entry_items)
    new_letter = next_letter
    return false if (journal_entry_items + statement_items).length.zero?

    statement_entries = JournalEntryItem.where(resource: statement_items)
    to_letter = journal_entry_items + statement_entries
    cash.suspense_account.mark(to_letter) if cash.suspend_until_reconciliation

    saved = true
    saved &&= statement_items.update_all(letter: new_letter)
    saved &&= journal_entry_items.update_all(
      bank_statement_letter: new_letter,
      bank_statement_id: id
    )

    saved && new_letter
  end

  def eligible_journal_entry_items
    unpointed = cash.unpointed_journal_entry_items
    pointed = JournalEntryItem.where.not(bank_statement_letter: nil).where(account_id: self.cash.account_id)
    eligible_items = JournalEntryItem.where(id: unpointed.pluck(:id) + pointed.pluck(:id))

    if cash.enable_bookkeep_bank_item_details
      bsi_journal_entries_id = items.pluck(:journal_entry_id)
      bsi_bookkeeped = JournalEntryItem.where(entry_id: bsi_journal_entries_id)
      eligible_items = eligible_items.where.not(id: bsi_bookkeeped.pluck(:id))
    end

    eligible_items
  end

  def eligible_entries_in(start, finish)
    unpointed = cash.unpointed_journal_entry_items.between(start, finish)
    pointed = JournalEntryItem.where.not(bank_statement_letter: nil).where(account_id: self.cash.account_id).between(start, finish)
    eligible_items = JournalEntryItem.where(id: unpointed.pluck(:id) + pointed.pluck(:id))

    if cash.enable_bookkeep_bank_item_details
      bsi_journal_entries_id = items.pluck(:journal_entry_id)
      bsi_bookkeeped = JournalEntryItem.where(entry_id: bsi_journal_entries_id)
      eligible_items = eligible_items.where.not(id: bsi_bookkeeped.pluck(:id))
    end

    eligible_items
  end

  def save_with_items(statement_items)
    ActiveRecord::Base.transaction do
      saved = save

      previous_journal_entry_item_ids_by_letter = items.each_with_object({}) do |item, hash|
        item.associated_journal_entry_items.each do |journal_entry_item|
          ids = (hash[journal_entry_item.bank_statement_letter] ||= [])
          ids << journal_entry_item.id
        end
      end

      items.clear

      statement_items.each_index do |index|
        statement_items[index] = items.build(statement_items[index])
        if started_on > statement_items[index].transfered_on
          statement_items[index].transfered_on = started_on
        end
        if statement_items[index].transfered_on > stopped_on
          statement_items[index].transfered_on = stopped_on
        end
        saved = false if saved && !statement_items[index].save
      end

      previous_journal_entry_item_ids_by_letter.each do |letter, journal_entry_item_ids|
        new_item_with_letter = items.detect { |item| item.letter == letter }
        if new_item_with_letter
          bank_statement_id = id
          bank_statement_letter = letter
        end
        JournalEntryItem.where(id: journal_entry_item_ids).update_all(
          bank_statement_id: bank_statement_id,
          bank_statement_letter: bank_statement_letter
        )
      end

      if saved && reload.save
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end

  private

  def clear_reconciliation_with_letters(letters)
    return unless letters.any?
    JournalEntryItem.where(bank_statement_letter: letters).update_all(
      bank_statement_id: nil,
      bank_statement_letter: nil
    )
    BankStatementItem.where(letter: letters).update_all(letter: nil)
  end
end
