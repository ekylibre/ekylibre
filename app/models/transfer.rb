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
# == Table: transfers
#
#  accounted_at     :datetime         
#  amount           :decimal(16, 2)   default(0.0), not null
#  comment          :string(255)      
#  company_id       :integer          not null
#  created_at       :datetime         not null
#  created_on       :date             
#  creator_id       :integer          
#  id               :integer          not null, primary key
#  journal_entry_id :integer          
#  label            :string(255)      
#  lock_version     :integer          default(0), not null
#  paid_amount      :decimal(16, 2)   default(0.0), not null
#  started_on       :date             
#  stopped_on       :date             
#  supplier_id      :integer          
#  updated_at       :datetime         not null
#  updater_id       :integer          
#


class Transfer < CompanyRecord
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :paid_amount, :allow_nil => true
  validates_length_of :comment, :label, :allow_nil => true, :maximum => 255
  #]VALIDATORS]
  attr_readonly :company_id, :comment
  belongs_to :company
  belongs_to :supplier, :class_name=>"Entity"
  belongs_to :client, :class_name=>"Entity", :foreign_key=>:supplier_id
  belongs_to :payer, :class_name=>"Entity", :foreign_key=>:supplier_id
  has_many :payment_uses, :as=>:expense, :class_name=>"IncomingPaymentUse"
  has_many :uses, :as=>:expense, :class_name=>"IncomingPaymentUse"

  validates_presence_of :created_on, :supplier

  before_validation do
    self.created_on ||= Date.today
    # self.paid_amount = self.payment_uses.sum(:amount)||0
  end

  #this method saves the transfer in the accountancy module.
  bookkeep(:on=>:nothing) do |b|
    #     b.journal_entry(action, {:journal=>self.company.journal(:purchases), :draft_mode=>options[:draft_mode]}) do |entry|
    #       entry.add_debit(self.supplier.full_name, self.supplier.account(:supplier), self.amount)
    #       entry.add_credit(tc(:payable_bills), "???Compte effets a payer", self.amount)      
    #     end
  end

  alias_attribute :client_id, :supplier_id

  def unpaid_amount
    self.amount - self.paid_amount
  end

  def number
    self.id.to_s
  end



end
