# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
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
# == Table: registered_phytosanitary_risks
#
#  product_id      :integer          not null
#  record_checksum :integer
#  risk_code       :string           not null
#  risk_phrase     :string           not null
#
class RegisteredPhytosanitaryRisk < ActiveRecord::Base
  include Lexiconable

  MENTIONS_TYPE = { 'H2' => :physical_h2, 'H3' => :health_h3, 'H4' => :environment_h4 }.freeze
  SYMBOLS_DESCRIPTION = { 'SGH01' => :explosive_substances,
                          'SGH02' => :flammable_agents,
                          'SGH03' => :combustion_agents,
                          'SGH04' => :under_pressure_or_refrigerated_gas,
                          'SGH05' => { 'H2' => :corrosive_substances, 'H3' => :corrosive_skin_and_mucosa_risks_of_severe_burns },
                          'SGH06' => :toxic,
                          'SGH07' => :irritating_by_skin_contact_and_inhalation_severe_eyes_irritation,
                          'SGH08' => :carcinogen_mutagenic_toxic_for_reproduction,
                          'SGH09' => :toxic_for_aquatic_organisms }.freeze

  belongs_to :product, class_name: 'RegisteredPhytosanitaryProduct'
  belongs_to :symbol, class_name: 'RegisteredPhytosanitarySymbol', foreign_key: :risk_code

  def decorated_symbol_name
    decorate.symbol_name
  end

  def type
    MENTIONS_TYPE[mentions.first(2)].tl
  end

  def description
    SYMBOLS_DESCRIPTION[symbol_name].is_a?(Hash) ? SYMBOLS_DESCRIPTION[symbol_name][mentions.first(2)].tl : SYMBOLS_DESCRIPTION[symbol_name].tl
  end
end
