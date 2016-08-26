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
# == Table: loan_repayments
#
#  accounted_at     :datetime
#  amount           :decimal(19, 4)   not null
#  base_amount      :decimal(19, 4)   not null
#  created_at       :datetime         not null
#  creator_id       :integer
#  due_on           :date             not null
#  id               :integer          not null, primary key
#  insurance_amount :decimal(19, 4)   not null
#  interest_amount  :decimal(19, 4)   not null
#  journal_entry_id :integer
#  loan_id          :integer          not null
#  lock_version     :integer          default(0), not null
#  position         :integer          not null
#  remaining_amount :decimal(19, 4)   not null
#  updated_at       :datetime         not null
#  updater_id       :integer
#
class LoanRepayment < Ekylibre::Record::Base
  belongs_to :journal_entry
  belongs_to :loan
  has_one :cash, through: :loan
  has_one :journal, through: :cash
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :amount, :base_amount, :insurance_amount, :interest_amount, :remaining_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :due_on, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  validates :loan, presence: true
  # ]VALIDATORS]
  delegate :currency, :name, to: :loan

  before_validation do
    self.amount = base_amount + insurance_amount + interest_amount
  end

  bookkeep do |b|
    b.journal_entry(journal, printed_on: due_on, if: (amount > 0 && due_on <= Time.zone.today)) do |entry|
      label = tc(:bookkeep, resource: self.class.model_name.human, name: name, year: due_on.year, month: due_on.month, position: position)
      entry.add_debit(label, Account.find_or_import_from_nomenclature(:loans).id, base_amount) unless base_amount.zero?
      entry.add_debit(label, Account.find_or_import_from_nomenclature(:loans_interests).id, interest_amount) unless interest_amount.zero?
      entry.add_debit(label, Account.find_or_import_from_nomenclature(:insurance_expenses).id, insurance_amount) unless insurance_amount.zero?
      entry.add_credit(label, cash.account_id, amount)
    end
  end
end
