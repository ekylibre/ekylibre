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
# == Table: currencies
#
#  active       :boolean          default(TRUE), not null
#  by_default   :boolean          not null
#  code         :string(255)      not null
#  comment      :text             
#  company_id   :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer          
#  format       :string(16)       not null
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  rate         :decimal(16, 6)   default(1.0), not null
#  symbol       :string(255)      default("-"), not null
#  updated_at   :datetime         not null
#  updater_id   :integer          
#


class Currency < CompanyRecord
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :rate, :allow_nil => true
  validates_length_of :format, :allow_nil => true, :maximum => 16
  validates_length_of :code, :name, :symbol, :allow_nil => true, :maximum => 255
  validates_inclusion_of :active, :by_default, :in => [true, false]
  validates_presence_of :code, :company, :format, :name, :rate, :symbol
  #]VALIDATORS]
  attr_readonly :company
  belongs_to :company
  has_many :journals
  has_many :prices
  has_many :cashes

  validates_uniqueness_of :code, :scope=>:company_id

  # Update the rates for all currencies of the company
  # if the reference (by_default) currency changes.
  after_validation(:on=>:update) do
    if (old = self.class.find_by_id(self.id))
      # If user thinks he needs to change the rate to 1 when he sets the currency by default
      # the conversions will be inefficients so to prevents this, it gets the old value
      self.rate = old.rate if self.rate == 1.0
      if old.by_default != self.by_default and self.by_default
        self.class.update_all([" rate=rate/? ", self.rate], {:company_id=>self.company_id})
      end
      # Useless theorically, but eliminates risks of decimals
      self.rate = 1.0
    end
  end

end
