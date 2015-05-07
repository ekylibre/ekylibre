# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_date :due_on, allow_blank: true, on_or_after: Date.civil(1, 1, 1)
  validates_datetime :accounted_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :amount, :base_amount, :insurance_amount, :interest_amount, :remaining_amount, allow_nil: true
  validates_presence_of :amount, :base_amount, :due_on, :insurance_amount, :interest_amount, :loan, :remaining_amount
  #]VALIDATORS]
  delegate :currency, :name, to: :loan

  before_validation do
    self.amount = self.base_amount + self.insurance_amount + self.interest_amount
  end

  bookkeep do |b|
    b.journal_entry(self.journal, printed_on: self.due_on, if: (self.amount > 0 and self.due_on <= Date.today)) do |entry|
      label = tc(:bookkeep, resource: self.class.model_name.human, name: self.name, year: self.due_on.year, month: self.due_on.month, position: self.position)
      entry.add_debit(label, Account.find_or_create_in_chart(:loans).id, self.base_amount) unless self.base_amount.zero?
      entry.add_debit(label, Account.find_or_create_in_chart(:loans_interests).id, self.interest_amount) unless self.interest_amount.zero?
      entry.add_debit(label, Account.find_or_create_in_chart(:insurance_expenses).id, self.insurance_amount) unless self.insurance_amount.zero?
      entry.add_credit(label, self.cash.account_id, self.amount)
    end
  end

end
