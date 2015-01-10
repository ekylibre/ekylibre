# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2015 Brice Texier, Thibaud Merigon
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
# 
# == Table: deposits
#
#  accounted_at     :datetime         
#  amount           :decimal(16, 4)   default(0.0), not null
#  cash_id          :integer          not null
#  comment          :text             
#  company_id       :integer          not null
#  created_at       :datetime         not null
#  created_on       :date             not null
#  creator_id       :integer          
#  id               :integer          not null, primary key
#  in_cash          :boolean          not null
#  journal_entry_id :integer          
#  lock_version     :integer          default(0), not null
#  locked           :boolean          not null
#  mode_id          :integer          not null
#  number           :string(255)      
#  payments_count   :integer          default(0), not null
#  responsible_id   :integer          
#  updated_at       :datetime         not null
#  updater_id       :integer          
#


class Deposit < CompanyRecord
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :allow_nil => true
  validates_length_of :number, :allow_nil => true, :maximum => 255
  validates_inclusion_of :in_cash, :locked, :in => [true, false]
  validates_presence_of :amount, :cash, :company, :created_on, :mode
  #]VALIDATORS]
  acts_as_numbered
  attr_readonly :company_id
  belongs_to :cash
  belongs_to :company
  belongs_to :responsible, :class_name=>"User"
  belongs_to :journal_entry
  belongs_to :mode, :class_name=>"IncomingPaymentMode"
  has_many :payments, :class_name=>"IncomingPayment", :dependent=>:nullify, :order=>"number"
  # has_many :journal_entries, :as=>:resource, :dependent=>:nullify, :order=>"created_at"

  validates_presence_of :responsible, :cash

  before_validation(:on=>:update) do
    self.payments_count = self.payments.count
    self.amount = self.payments.sum(:amount)
  end

  validate do
    if self.cash
      error.add(:cash_id, :must_be_a_bank_account) unless self.cash.bank_account?
    end
  end

  # This method permits to add journal entries corresponding to the payment
  # It depends on the preference which permit to activate the "automatic bookkeeping"
  bookkeep do |b|
    payments = self.reload.payments unless b.action == :destroy
    b.journal_entry(self.cash.journal, :if=>!self.mode.depositables_account.nil?) do |entry|

      commissions, commissions_amount = {}, 0
      for payment in payments
        commissions[payment.commission_account_id.to_s] ||= 0
        commissions[payment.commission_account_id.to_s] += payment.commission_amount
        commissions_amount += payment.commission_amount
      end

      label = tc(:bookkeep, :resource=>self.class.model_name.human, :number=>self.number, :count=>self.payments_count, :mode=>self.mode.name, :responsible=>self.responsible.label, :comment=>self.comment)
      
      entry.add_debit( label, self.cash.account_id, self.amount-commissions_amount)
      for commission_account_id, commission_amount in commissions
        entry.add_debit( label, commission_account_id.to_i, commission_amount) if commission_amount > 0
      end

      if self.company.prefer_detail_payments_in_deposit_bookkeeping?
        for payment in payments
          label = tc(:bookkeep_with_payment, :resource=>self.class.model_name.human, :number=>self.number, :mode=>self.mode.name, :payer=>payment.payer.full_name, :check_number=>payment.check_number, :payment=>payment.number)
          entry.add_credit(label, self.mode.depositables_account_id, payment.amount)
        end
      else
        entry.add_credit(label, self.mode.depositables_account_id, self.amount)
      end
      true
    end
  end

  protect_on_destroy do
    return !self.locked?
  end

  def refresh
    self.save
  end

end
