# = Informations
#
# == License
#
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
# == Table: catalogs
#
#  all_taxes_included :boolean          not null
#  by_default         :boolean          not null
#  code               :string(20)       not null
#  created_at         :datetime         not null
#  creator_id         :integer
#  currency           :string(3)        not null
#  description        :text
#  id                 :integer          not null, primary key
#  lock_version       :integer          default(0), not null
#  name               :string(255)      not null
#  updated_at         :datetime         not null
#  updater_id         :integer
#  usage              :string(20)       not null
#


class Catalog < Ekylibre::Record::Base
  enumerize :usage, in: [:purchase, :sale, :stock, :cost], default: :sale
  has_many :active_prices, -> { where(active: true) }, class_name: "CatalogPrice"
  has_many :prices, class_name: "CatalogPrice", dependent: :destroy, inverse_of: :catalog
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :currency, allow_nil: true, maximum: 3
  validates_length_of :code, :usage, allow_nil: true, maximum: 20
  validates_length_of :name, allow_nil: true, maximum: 255
  validates_inclusion_of :all_taxes_included, :by_default, in: [true, false]
  validates_presence_of :code, :currency, :name, :usage
  #]VALIDATORS]
  validates_uniqueness_of :code

  selects_among_all scope: :usage

  scope :of_usage, lambda { |usage|
    where(usage: usage.to_s)
  }

  before_validation do
    self.currency ||= Preference[:currency]
    self.code = self.name.to_s.codeize if self.code.blank?
    self.code = self.code[0..19]
  end

  protect(on: :destroy) do
    self.prices.any?
  end

end
