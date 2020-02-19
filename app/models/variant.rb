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
# == Table: variants
#
#  category            :string
#  class_name          :string
#  default_unit        :string
#  eu_product_code     :string
#  id                  :string           not null, primary key
#  indicators          :jsonb
#  label_fra           :string           not null
#  name                :jsonb
#  nature              :string
#  reference_name      :string           not null
#  specie              :string
#  sub_nature          :string
#  target_specie       :string
#  variant_category_id :integer
#  variant_nature_id   :integer
#
class Variant < ActiveRecord::Base
  include Lexiconable
  include ScopeIntrospection

  belongs_to :variant_category
  belongs_to :variant_type

  scope :of_class_name, -> (*class_names) { where(class_name: class_names) }
  scope :of_sub_nature, -> (*sub_natures) { where(sub_nature: sub_natures) }
end
