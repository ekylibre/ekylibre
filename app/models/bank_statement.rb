# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
  has_many :items, class_name: 'BankStatementItem', dependent: :destroy, inverse_of: :bank_statement
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :started_on, :stopped_on, timeliness: { allow_blank: true, on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  validates_datetime :stopped_on, allow_blank: true, on_or_after: :started_on, if: ->(bank_statement) { bank_statement.stopped_on && bank_statement.started_on }
  validates :credit, :debit, :initial_balance_credit, :initial_balance_debit, numericality: { allow_nil: true }
  validates :cash, :credit, :currency, :debit, :initial_balance_credit, :initial_balance_debit, :number, :started_on, :stopped_on, presence: true
  # ]VALIDATORS]
  validates :currency, length: { allow_nil: true, maximum: 3 }
  validates :number, uniqueness: { scope: :cash_id }

  accepts_nested_attributes_for :items, reject_if: proc { |params| params['name'].blank? && params['transfered_on'].blank? && params['debit'].to_f.zero? && params['credit'].to_f.zero? }, allow_destroy: true

  delegate :name, :currency, :account_id, :next_reconciliation_letters, to: :cash, prefix: true

  before_validation do
    self.currency = cash_currency if cash
    self.debit  = items.sum(:debit)
    self.credit = items.sum(:credit)
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
      if started_on >= stopped_on
        errors.add(:stopped_on, :posterior, to: started_on.l)
      end
    end
    if initial_balance_debit != 0 && initial_balance_credit != 0
      errors.add(:initial_balance_credit, :unvalid_amounts)
    end
  end

  def balance_credit
    (debit > credit ? 0.0 : credit - debit)
  end

  def balance_debit
    (debit > credit ? debit - credit : 0.0)
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

  def eligible_journal_entry_items
    margin = 20.days
    unpointed = JournalEntryItem.where(account_id: cash_account_id).unpointed.between(started_on - margin, stopped_on + margin)
    pointed = JournalEntryItem.pointed_by(self)
    JournalEntryItem.where(id: unpointed.pluck(:id) + pointed.pluck(:id))
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
end
