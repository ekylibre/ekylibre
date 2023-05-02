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
# == Table: master_variant_natures
#
#  abilities           Array<:text>
#  derivative_of       :string
#  family              :string           not null
#  frozen_indicators   Array<:text>
#  pictogram           :string
#  population_counting :string           not null
#  reference_name      :string           not null, primary key
#  translation_id      :string           not null
#  variable_indicators Array<:text>
#  variety             :string           not null
#
class MasterVariantNature < LexiconRecord
  extend Enumerize
  include Lexiconable
  include ScopeIntrospection

  belongs_to :translation, class_name: 'MasterTranslation'
  enumerize :population_counting, in: %i[unitary integer decimal], predicates: { prefix: true }

  scope :of_families, ->(*families) { where(family: families) }
  scope :of_class_name, ->(*class_names) { where(nature: class_names) }

  # convert 'uf940-seedling-solid.svg' to 'seedling-solid'
  def pictogram_name
    if pictogram.present?
      a = pictogram.split('.')
      a.pop
      b = a.first.split('-')
      b.shift
      b.join('-')
    else
      nil
    end
  end

end
