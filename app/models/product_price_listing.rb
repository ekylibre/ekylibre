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
# == Table: product_price_listings
#
#  by_default   :boolean          not null
#  code         :string(8)
#  created_at   :datetime         not null
#  creator_id   :integer
#  description  :text
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#


class ProductPriceListing < Ekylibre::Record::Base
  attr_accessible :name, :description, :by_default, :code
  has_many :active_prices, :class_name => "ProductPrice", :foreign_key => :listing_id, :conditions => {:active => true}
  has_many :entities, :foreign_key => :sale_price_listing_id
  has_many :prices, :class_name => "ProductPrice", :foreign_key => :listing_id
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :code, :allow_nil => true, :maximum => 8
  validates_length_of :name, :allow_nil => true, :maximum => 255
  validates_inclusion_of :by_default, :in => [true, false]
  validates_presence_of :name
  #]VALIDATORS]
  validates_uniqueness_of :code

  has_default

  before_validation do
    self.code = self.name.to_s.codeize if self.code.blank?
    self.code = self.code[0..7]
  end

  protect(:on => :destroy) do
    self.entities.count <= 0 and self.prices.count <= 0
  end

end
