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
# == Table: master_variants
#
#  category       :string           not null
#  default_unit   :string           not null
#  family         :string           not null
#  indicators     :jsonb
#  name_tags      Array<:text>
#  nature         :string           not null
#  pictogram      :string
#  reference_name :string           not null, primary key
#  specie         :string
#  sub_family     :string
#  target_specie  :string
#  translation_id :string           not null
#
class MasterVariant < LexiconRecord
  include Lexiconable
  include ScopeIntrospection

  belongs_to :master_variant_category, foreign_key: :category
  belongs_to :master_variant_nature, foreign_key: :nature
  belongs_to :translation, class_name: 'MasterTranslation'

  scope :of_families, ->(*families) { where(family: families) }
  scope :of_sub_families, ->(*sub_families) { where(sub_family: sub_families) }

  # convert 'uf940-seedling-solid.svg' to 'seedling-solid'
  def pictogram_name
    if pictogram.present?
      a = pictogram.split('.')
      a.pop
      if a.present?
        b = a.first.split('-')
        b.shift
        b.join('-')
      else
        nil
      end
    else
      nil
    end
  end

end
