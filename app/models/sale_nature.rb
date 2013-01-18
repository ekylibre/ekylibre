# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
# == Table: sale_natures
#
#  active                  :boolean          default(TRUE), not null
#  comment                 :text             
#  created_at              :datetime         not null
#  creator_id              :integer          
#  currency                :string(3)        
#  downpayment             :boolean          not null
#  downpayment_minimum     :decimal(19, 4)   default(0.0), not null
#  downpayment_percentage  :decimal(19, 4)   default(0.0), not null
#  expiration_id           :integer          not null
#  id                      :integer          not null, primary key
#  journal_id              :integer          
#  lock_version            :integer          default(0), not null
#  name                    :string(255)      not null
#  payment_delay_id        :integer          not null
#  payment_mode_complement :text             
#  payment_mode_id         :integer          
#  sales_conditions        :text             
#  updated_at              :datetime         not null
#  updater_id              :integer          
#  with_accounting         :boolean          not null
#


class SaleNature < CompanyRecord
  attr_accessible :name, :journal, :active, :comment, :currency, :downpayment, :downpayment_minimum, :downpayment_percentage, :expiration_id, :journal_id, :payment_delay_id, :payment_mode_complement, :payment_mode_id, :sales_conditions, :with_accounting
  belongs_to :journal
  belongs_to :expiration, :class_name=>"Delay"
  belongs_to :payment_delay, :class_name=>"Delay"
  belongs_to :payment_mode, :class_name=>"IncomingPaymentMode"
  has_many :sales
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :downpayment_minimum, :downpayment_percentage, :allow_nil => true
  validates_length_of :currency, :allow_nil => true, :maximum => 3
  validates_length_of :name, :allow_nil => true, :maximum => 255
  validates_inclusion_of :active, :downpayment, :with_accounting, :in => [true, false]
  validates_presence_of :downpayment_minimum, :downpayment_percentage, :expiration, :name, :payment_delay
  #]VALIDATORS]
  validates_presence_of :journal, :if=>Proc.new{|sn| sn.with_accounting?}
  validates_presence_of :currency
  validates_uniqueness_of :name

  validate do
    if self.journal
      unless self.currency == self.journal.currency
        errors.add(:journal, :currency_does_not_match)
      end
    end
    if self.payment_mode
      unless self.currency == self.payment_mode.cash.currency
        errors.add(:payment_mode, :currency_does_not_match)
      end
    end
  end

end
