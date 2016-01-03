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
#  cash_id      :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer
#  credit       :decimal(19, 4)   default(0.0), not null
#  currency     :string           not null
#  debit        :decimal(19, 4)   default(0.0), not null
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  number       :string           not null
#  started_at   :datetime         not null
#  stopped_at   :datetime         not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#

class BankStatement < Ekylibre::Record::Base
  include Attachable
  belongs_to :cash
  has_many :items, class_name: 'JournalEntryItem', dependent: :nullify
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :started_at, :stopped_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :credit, :debit, allow_nil: true
  validates_presence_of :cash, :credit, :currency, :debit, :number, :started_at, :stopped_at
  # ]VALIDATORS]
  validates_length_of :currency, allow_nil: true, maximum: 3
  validates_uniqueness_of :number, scope: :cash_id

  delegate :name, :currency, :account_id, to: :cash, prefix: true

  before_validation do
    self.currency = cash_currency if cash
    self.debit  = items.sum(:real_debit)
    self.credit = items.sum(:real_credit)
  end

  # A bank account statement has to contain.all the planned records.
  validate do
    if started_at && stopped_at
      if started_at >= stopped_at
        errors.add(:stopped_at, :posterior, to: started_at.l)
      end
    end
  end

  def balance_credit
    (debit > credit ? 0.0 : credit - debit)
  end

  def balance_debit
    (debit > credit ? debit - credit : 0.0)
  end

  def previous
    self.class.where('stopped_at <= ?', started_at).reorder(stopped_at: :desc).first
  end

  def next
    self.class.where('started_at >= ?', stopped_at).reorder(started_at: :asc).first
  end

  def eligible_items
    JournalEntryItem.where('bank_statement_id = ? OR (account_id = ? AND (bank_statement_id IS NULL OR journal_entries.created_at BETWEEN ? AND ?))', id, cash_account_id, started_at, stopped_at).joins("INNER JOIN #{JournalEntry.table_name} AS journal_entries ON journal_entries.id = entry_id").order("bank_statement_id DESC, #{JournalEntry.table_name}.printed_on DESC, #{JournalEntryItem.table_name}.position")
  end

  def point(item_ids)
    return false if self.new_record?
    JournalEntryItem.where(bank_statement_id: id).update_all(bank_statement_id: nil)
    JournalEntryItem.where(bank_statement_id: nil, id: item_ids).update_all(bank_statement_id: id)
    # Computes debit and credit
    self.save!
    true
  end
end
