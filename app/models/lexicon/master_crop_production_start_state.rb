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
# == Table: master_crop_productions
#
#  agroedi_crop_code         :string
#  id                        :integer          not null, primary key
#  life_duration             :decimal(5, 2)
#  main_input                :string
#  season                    :string
#  specie                    :string           not null
#  start_state_of_production :jsonb
#  started_on                :date             not null
#  stopped_on                :date             not null
#
class MasterCropProductionStartState < LexiconRecord
  include Lexiconable

  belongs_to :production_nature, class_name: 'MasterCropProduction', foreign_key: :production, inverse_of: :start_states

  def self.defaults
    (1..5).map { |year| new(year: year, key: "n_#{year}") }
  end

  def default?
    false
  end

  # @param [String] :locale
  # @return [String]
  def label(locale: I18n.default_locale)
    I18n.t(key, scope: "lexicon.start_state_of_production", locale: locale)
  end
end
