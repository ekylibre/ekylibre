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
# == Table: taxes
#
#  amount               :decimal(19, 4)   default(0.0), not null
#  collected_account_id :integer
#  created_at           :datetime         not null
#  creator_id           :integer
#  description          :text
#  id                   :integer          not null, primary key
#  included             :boolean          not null
#  lock_version         :integer          default(0), not null
#  name                 :string(255)      not null
#  nature               :string(16)       not null
#  paid_account_id      :integer
#  reductible           :boolean          default(TRUE), not null
#  updated_at           :datetime         not null
#  updater_id           :integer
#


class Tax < Ekylibre::Record::Base
  attr_accessible :name, :nature, :collected_account_id, :description, :included, :paid_account_id, :reductible, :amount
  attr_readonly :nature, :amount
  enumerize :nature, :in => [:amount, :percentage], :default => :percentage, :predicates => true
  belongs_to :collected_account, :class_name => "Account"
  belongs_to :paid_account, :class_name => "Account"
  has_many :price_templates, :class_name => "ProductPriceTemplate"
  has_many :prices, :class_name => "ProductPrice"
  # TODO has_many :purchase_items
  has_many :sale_items
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :allow_nil => true
  validates_length_of :nature, :allow_nil => true, :maximum => 16
  validates_length_of :name, :allow_nil => true, :maximum => 255
  validates_inclusion_of :included, :reductible, :in => [true, false]
  validates_presence_of :amount, :name, :nature
  #]VALIDATORS]
  validates_inclusion_of :nature, :in => self.nature.values
  validates_presence_of :collected_account
  validates_presence_of :paid_account
  validates_uniqueness_of :name
  validates_numericality_of :amount, :in => 0..100, :if => :percentage?

  scope :percentages, -> { where(:nature => 'percentage') }

  protect(:on => :destroy) do
    self.prices.count <= 0 and self.sale_items.count <= 0 #  and self.purchase_items.count <= 0
  end

  # Compute the tax amount
  # If +with_taxes+ is true, it's considered that the given amount
  # is an amount with tax
  def compute(amount, with_taxes = false)
    if self.percentage? and with_taxes
      amount.to_d / (1 + 100/self.amount.to_d)
    elsif self.percentage?
      amount.to_d * self.amount.to_d/100
    elsif self.amount?
      self.amount
    end
  end


  # Returns the pretax amount of an amount
  def pretax_amount_of(amount)
    return (self.percentage? ? (amount.to_d / coefficient) : (amount.to_d - self.amount.to_d))
  end

  # Returns the amount of a pretax amount
  def amount_of(pretax_amount)
    return (self.percentage? ? (pretax_amount.to_d * coefficient) : (pretax_amount.to_d + self.amount.to_d))
  end

  # Returns the matching coefficient k of the percentage
  # where pretax_amount * k = amount_with_tax
  def coefficient
    raise StandardError("Can only use coefficient method with percentage taxes") unless self.percentage?
    return (1.0 + 0.01*self.amount.to_d)
  end



end
