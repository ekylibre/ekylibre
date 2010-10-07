# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2010 Brice Texier, Thibaud Mérigon
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

class Deposit < ActiveRecord::Base
  acts_as_accountable
  attr_readonly :company_id
  belongs_to :cash
  belongs_to :company
  belongs_to :responsible, :class_name=>User.name
  belongs_to :journal_entry
  belongs_to :mode, :class_name=>SalePaymentMode.name
  has_many :payments, :class_name=>SalePayment.name, :dependent=>:nullify, :order=>"number"
  # has_many :journal_entries, :as=>:resource, :dependent=>:nullify, :order=>"created_at"

  validates_presence_of :responsible, :number, :cash

  def prepare_on_create
    specific_numeration = self.company.preference("management.deposits.numeration")
    if specific_numeration and specific_numeration.value
      self.number = specific_numeration.value.next_value
    else
      last = self.company.deposits.find(:first, :conditions=>["company_id=? AND number IS NOT NULL", self.company_id], :order=>"number desc")
      self.number = last ? last.number.succ : '000001'
    end
  end

  def prepare_on_update
    self.payments_count = self.payments.count
    self.amount = self.payments.sum(:amount)
  end

  def check
    if self.cash
      error.add(:cash_id, :must_be_a_bank_account) unless self.cash.bank_account?
    end
  end

  def refresh
    self.save
  end

  # this method valids the deposit and accountizes the matching payments.
  # def confirm
  #     payments = SalePayment.find_all_by_company_id_and_deposit_id(self.company_id, self.id)
  #     payments.each do |payment|
  #       payment.to_accountancy
  #     end
  #   end

  # This method permits to add journal entries corresponding to the payment
  # It depends on the preference which permit to activate the "automatic accountizing"
  def to_accountancy(action=:create, options={})
    payments = self.reload.payments
    accountize(action, {:journal=>self.cash.journal, :draft_mode=>options[:draft]}) do |entry|

      commissions, commissions_amount = {}, 0
      for payment in payments
        commissions[payment.commission_account_id.to_s] ||= 0
        commissions[payment.commission_account_id.to_s] += payment.commission_amount
        commissions_amount += payment.commission_amount
      end

      label = tc(:to_accountancy, :resource=>self.class.human_name, :number=>self.number, :count=>self.payments_count, :mode=>self.mode.name, :responsible=>self.responsible.label, :comment=>self.comment)
      
      entry.add_debit( label, self.cash.account_id, self.amount-commissions_amount)
      for commission_account_id, commission_amount in commissions
        entry.add_debit( label, commission_account_id.to_i, commission_amount)
      end

      if self.company.preference("accountancy.accountize.detail_payments_in_deposits").value
        for payment in payments
          label = tc(:to_accountancy_with_payment, :resource=>self.class.human_name, :number=>self.number, :mode=>self.mode.name, :payer=>payment.payer.full_name, :check_number=>payment.check_number, :payment=>payment.number)
          entry.add_credit(label, self.mode.depositables_account_id, payment.amount)
        end
      else
        entry.add_credit(label, self.mode.depositables_account_id, self.amount)
      end
      true
    end
  end

end
