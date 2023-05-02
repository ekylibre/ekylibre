# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
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
# == Table: registered_eu_market_prices
#
#  category                  :string
#  country                   :string
#  end_date                  :date
#  id                        :string           not null, primary key
#  nature                    :string
#  price                     :decimal(8, 2)
#  product_code              :string
#  product_description       :string
#  product_label             :string
#  production_reference_name :string
#  sector_code               :string
#  specie                    :string
#  start_date                :date
#  unit_name                 :string
#  unit_value                :integer(4)
#
class RegisteredEuMarketPrice < LexiconRecord
  include Lexiconable
  scope :of_specie, ->(specie) { where(specie: specie.to_s) }
  scope :of_country, ->(country) { where(country: country.to_s) }
  scope :between, lambda { |started_on, stopped_on|
    where(start_date: started_on..stopped_on)
  }

end
