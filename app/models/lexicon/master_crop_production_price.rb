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
class MasterCropProductionPrice < LexiconRecord
  include Lexiconable

  scope :of_variety, ->(variety) { where(specie: variety.to_s) }
  scope :of_production_reference, ->(production_reference) { where(production_reference_name: production_reference.to_s) }
  scope :is_organic, -> { where(organic: true) }
  scope :of_organic, ->(organic) { where(organic: organic) }
  scope :of_harvest_year, ->(harvest_year) { where(campaign: harvest_year.to_i) }
  scope :of_output, ->(variety_output) { where(product_output_specie: variety_output.to_s) }
  scope :of_department, ->(department) { where(department_zone: department.to_i.to_s) }
  scope :of_departments, ->(*departments) { where(department_zone: departments) }
  scope :between, lambda { |started_on, stopped_on|
    where(started_on: started_on..stopped_on)
  }

end
