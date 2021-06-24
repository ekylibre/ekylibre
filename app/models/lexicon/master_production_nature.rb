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
# == Table: master_production_natures
#
#  agroedi_crop_code         :string
#  cap_2017_crop_code        :string
#  cap_2018_crop_code        :string
#  cap_2019_crop_code        :string
#  cap_2020_crop_code        :string
#  human_name                :jsonb
#  human_name_fra            :string           not null
#  id                        :integer          not null, primary key
#  life_duration             :decimal(5, 2)
#  main_input                :string
#  pfi_crop_code             :string
#  season                    :string
#  specie                    :string           not null
#  start_state_of_production :jsonb
#  started_on                :date             not null
#  stopped_on                :date             not null
#
class MasterProductionNature < LexiconRecord
  class StartStateOfProduction
    # @return [Integer]
    attr_reader :year
    # @return [MasterProductionNature]
    attr_reader :specie
    # @return [Symbol]
    attr_reader :key

    def initialize(year:, key:, production_nature: nil, default: false)
      @year = year
      @key = key
      @production_nature = production_nature
      @default = default
    end

    # @return [Boolean]
    def default?
      @default
    end

    # @param [String] :locale
    # @return [String]
    def label(locale: I18n.default_locale)
      I18n.t(key, scope: "lexicon.start_state_of_production", locale: locale)
    end
  end

  ARBITRARY_CHOOSEN_YEAR = 2000

  include Lexiconable
  include ScopeIntrospection

  belongs_to :pfi_crop, class_name: 'RegisteredPfiCrop', foreign_key: :pfi_crop_code
  has_many :outputs, class_name: 'MasterProductionOutput', inverse_of: :production_nature, foreign_key: :production_nature_id

  scope :of_species, ->(*species) { where(specie: species) }

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

  # @return [Hash{Integer => StartStateOfProduction}]
  def start_state_of_production
    return {} if self[:start_state_of_production].nil?

    value = self[:start_state_of_production]
    value.map do |year, key|
      [year.to_i, StartStateOfProduction.new(year: year.to_i, key: key,  production_nature: self )]
    end.to_h
  end

  # @return [String]
  def cycle
    start_state_of_production.any? ? 'perennial' : 'annual'
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
