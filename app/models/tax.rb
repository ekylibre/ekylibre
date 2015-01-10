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
# == Table: taxes
#
#  amount               :decimal(16, 4)   default(0.0), not null
#  collected_account_id :integer          
#  company_id           :integer          not null
#  created_at           :datetime         not null
#  creator_id           :integer          
#  description          :text             
#  id                   :integer          not null, primary key
#  included             :boolean          not null
#  lock_version         :integer          default(0), not null
#  name                 :string(255)      not null
#  nature               :string(8)        not null
#  paid_account_id      :integer          
#  reductible           :boolean          default(TRUE), not null
#  updated_at           :datetime         not null
#  updater_id           :integer          
#


class Tax < CompanyRecord
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :allow_nil => true
  validates_length_of :nature, :allow_nil => true, :maximum => 8
  validates_length_of :name, :allow_nil => true, :maximum => 255
  validates_inclusion_of :included, :reductible, :in => [true, false]
  validates_presence_of :amount, :company, :name, :nature
  #]VALIDATORS]
  attr_readonly :nature, :company_id #, :amount
  belongs_to :company
  belongs_to :collected_account, :class_name=>"Account"
  belongs_to :paid_account, :class_name=>"Account"
  has_many :prices
  has_many :sale_lines
  validates_inclusion_of :nature, :in=>%w( amount percent )
  validates_presence_of :collected_account_id
  validates_presence_of :paid_account_id
  validates_uniqueness_of :name, :scope=>:company_id
  validates_numericality_of :amount, :in=>0..100, :if=>Proc.new{|x| x.percent?}


  protect_on_destroy do
    self.prices.size <= 0 and self.sale_lines.size <= 0
  end
  
  def compute(amount, with_taxes=false)
    if self.percent? and with_taxes
      amount.to_f / (1 + 100/self.amount.to_f)
    elsif self.percent?
      amount.to_f*self.amount.to_f/100
    elsif self.amount?
      self.amount
    end
  end

  def percent?
    return (self.nature.to_s == "percent")
  end
  
  def amount?
    self.nature == "amount"
  end

  def self.natures
     [:percent, :amount].collect{|x| [tc('natures.'+x.to_s), x] }
  end

  def nature_label
    tc('natures.'+self.nature.to_s)
  end
  
end
