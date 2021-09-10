# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2021 Ekylibre SAS
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
# == Table: registered_protected_designation_of_origins
#
#  eu_sign                :string
#  fr_sign                :string
#  geographic_area        :string
#  id                     :integer          not null, primary key
#  ida                    :integer          not null
#  product_human_name     :jsonb
#  product_human_name_fra :string
#  reference_number       :string
#
class RegisteredEuMarketPrice < LexiconRecord
  include Lexiconable
  VARIETY_TO_PRODUCT_CODE = { avena_sativa: %w[AVOMILL AVO],
                              hordeum_vulgare: %w[ORGBRAS ORGFOUR],
                              triticum_aestivum: %w[BLTFOUR BLTPAN],
                              triticum_durum: ['DUR'],
                              zea_mays: ['MAI'] }.freeze
  scope :of_variety, ->(variety) { where(product_code: VARIETY_TO_PRODUCT_CODE[variety.to_sym]) }
  scope :of_country, ->(country) { where(country: country.to_s) }
  scope :between, lambda { |started_on, stopped_on|
    where(start_date: started_on..stopped_on)
  }

end
