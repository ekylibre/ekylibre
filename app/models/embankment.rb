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
# == Table: embankments
#
#  accounted_at      :datetime         
#  amount            :decimal(16, 4)   default(0.0), not null
#  cash_id           :integer          not null
#  comment           :text             
#  company_id        :integer          not null
#  created_at        :datetime         not null
#  created_on        :date             not null
#  creator_id        :integer          
#  embanker_id       :integer          
#  id                :integer          not null, primary key
#  journal_record_id :integer          
#  lock_version      :integer          default(0), not null
#  locked            :boolean          not null
#  mode_id           :integer          not null
#  number            :string(255)      
#  payments_count    :integer          default(0), not null
#  updated_at        :datetime         not null
#  updater_id        :integer          
#

class Embankment < ActiveRecord::Base
  acts_as_accountable
  attr_readonly :company_id
  belongs_to :cash
  belongs_to :company
  belongs_to :embanker, :class_name=>User.name
  belongs_to :journal_record
  belongs_to :mode, :class_name=>SalePaymentMode.name
  has_many :payments, :class_name=>SalePayment.name, :dependent=>:nullify, :order=>"number"
  has_many :journal_records, :as=>:resource, :dependent=>:nullify, :order=>"created_at"

  validates_presence_of :embanker, :number, :cash

  def before_validation_on_create
    specific_numeration = self.company.parameter("management.embankments.numeration")
    if specific_numeration and specific_numeration.value
      self.number = specific_numeration.value.next_value
    else
      last = self.company.embankments.find(:first, :conditions=>["company_id=? AND number IS NOT NULL", self.company_id], :order=>"number desc")
      self.number = last ? last.number.succ : '000000'
    end
  end

  def before_validation_on_update
    self.payments_count = self.payments.count
    self.amount = self.payments.sum(:amount)
  end

  def validate
    if self.cash
      error.add(:cash_id, :must_be_a_bank_account) unless self.cash.bank_account?
    end
  end

  def refresh
    self.save
  end

  # this method valids the embankment and accountizes the matching payments.
  # def confirm
  #     payments = SalePayment.find_all_by_company_id_and_embankment_id(self.company_id, self.id)
  #     payments.each do |payment|
  #       payment.to_accountancy
  #     end
  #   end

  # This method permits to add journal entries corresponding to the payment
  # It depends on the parameter which permit to activate the "automatic accountizing"
  def to_accountancy(action=:create, options={})
    accountize(action, {:journal=>self.cash.journal, :draft_mode=>options[:draft]}) do |record|
      label = tc(:to_accountancy, :resource=>self.class.human_name, :number=>self.number, :count=>self.payments_count, :mode=>self.mode.name, :embanker=>self.embanker.label, :comment=>self.comment)
      record.add_debit( label, self.cash.account_id, self.amount)
      if self.company.parameter("accountancy.accountize.detail_payments_in_embankments").value
        for payment in self.payments
          label = tc(:to_accountancy_with_payment, :resource=>self.class.human_name, :number=>self.number, :mode=>self.mode.name, :payer=>payment.payer.full_name, :check_number=>payment.check_number, :payment=>payment.number)
          record.add_credit(label, self.mode.embankables_account_id, payment.amount)
        end
      else
        record.add_credit(label, self.mode.embankables_account_id, self.amount)
      end
    end
  end

end
