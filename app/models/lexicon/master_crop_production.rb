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
class MasterCropProduction < LexiconRecord
  ARBITRARY_CHOOSEN_YEAR = 2000

  include Lexiconable
  include ScopeIntrospection
  include HasInterval

  belongs_to :translation, class_name: 'MasterTranslation'
  has_many :cap_codes, class_name: 'MasterCropProductionCapCode', foreign_key: :production
  has_one :pfi_crop, -> { where('campaign = 2020') }, class_name: 'MasterCropProductionTfiCode', foreign_key: :production
  has_many :outputs, class_name: 'MasterProductionOutput', inverse_of: :production_nature, foreign_key: :production_nature_id
  has_many :start_states, class_name: 'MasterCropProductionStartState', inverse_of: :production_nature, foreign_key: :production

  scope :of_species, ->(*species) { where(specie: species) }

  has_interval :life_duration

  # @return [String] Name of the main associated output
  def main_output_name
    if outputs.any?
      outputs.main.first.name
    end
  end

  # Compute start date for a production nature (DD-MM)  and a harvest year (YYYY)
  #
  # @return [Date, nil]
  def start_on(harvest_year)
    if started_on && stopped_on && harvest_year
      year_gap = stopped_on.year - started_on.year
      start = Date.new(harvest_year - year_gap, started_on.month, started_on.day)
    else
      nil
    end
  end

  # @return Date
  # compute stop date for a production nature (DD-MM)  and a harvest year (YYYY)
  def stop_on(harvest_year)
    if stopped_on && harvest_year
      stop = Date.new(harvest_year, stopped_on.month, stopped_on.day)
    else
      nil
    end
  end

  # @return [String]
  def cycle
    start_states.any? ? 'perennial' : 'annual'
  end

  # @return [Boolean]
  def perennial?
    cycle == 'perennial'
  end

  # TODO: Must be corrected in lexicon to avoid if statement
  # @return [Integer]
  def started_on_year
    if started_on.year == stopped_on.year
      started_on.year - ARBITRARY_CHOOSEN_YEAR
    else
      started_on.year - ARBITRARY_CHOOSEN_YEAR - 1
    end
  end

  # @return [Integer]
  def stopped_on_year
    if started_on.year == stopped_on.year
      stopped_on.year - ARBITRARY_CHOOSEN_YEAR
    else
      stopped_on.year - ARBITRARY_CHOOSEN_YEAR - 1
    end
  end
end
