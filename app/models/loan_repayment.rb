# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2018 Brice Texier, David Joulin
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
#  accountable      :boolean          default(FALSE), not null
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
#  locked           :boolean          default(FALSE), not null
#  position         :integer          not null
#  remaining_amount :decimal(19, 4)   not null
#  updated_at       :datetime         not null
#  updater_id       :integer
#
class LoanRepayment < Ekylibre::Record::Base
  belongs_to :journal_entry
  belongs_to :loan
  has_one :cash, through: :loan
  has_one :lender, through: :loan
  has_one :journal, through: :cash
  has_one :third, through: :loan # alias for lender
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accountable, :locked, inclusion: { in: [true, false] }
  validates :accounted_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :amount, :base_amount, :insurance_amount, :interest_amount, :remaining_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :due_on, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  validates :loan, presence: true
  # ]VALIDATORS]
  delegate :currency, :name, to: :loan

  scope :of_loans, lambda { |ids|
    where(loan_id: ids)
  }

  scope :bookkeepable_before, lambda { |limit_on|
    where('accountable IS FALSE AND journal_entry_id IS NULL AND due_on <= ?', limit_on)
  }

  before_validation do
    self.base_amount ||= 0
    self.insurance_amount ||= 0
    self.interest_amount ||= 0
    self.amount = base_amount + insurance_amount + interest_amount
  end

  # Prevents from deleting if entry exist
  protect on: %i[destroy] do
    journal_entry
  end

  bookkeep do |b|
    # when payment arrive (due_on)
    financial_year = FinancialYear.on(due_on)
    # puts [journal.writable_on?(due_on), !locked, accountable, amount > 0, due_on <= Time.zone.today, financial_year.present?, loan.ongoing?].inspect.yellow
    unsuppress do
      b.journal_entry(journal, printed_on: due_on, if: (!locked && accountable && amount > 0 && due_on <= Time.zone.today && financial_year.present? && loan.ongoing?)) do |entry|
        label = tc(:bookkeep, resource: self.class.model_name.human, name: name, year: due_on.year, month: due_on.month, position: position)
        # puts label.inspect.magenta
        entry.add_debit(label, unsuppress { loan.loan_account_id }, base_amount, as: :repayment)
        entry.add_debit(label, unsuppress { loan.interest_account_id }, interest_amount, as: :interest)
        entry.add_debit(label, unsuppress { loan.insurance_account_id }, insurance_amount, as: :insurance) if insurance_amount.nonzero?
        entry.add_credit(label, cash.account_id, amount, as: :bank)
      end
    end
    true
  end

  def number
    loan.name + ' ' + position.to_s
  end
end
