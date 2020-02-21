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
# == Table: variant_categories
#
#  default_vat_rate               :decimal(5, 2)
#  depreciable                    :boolean
#  depreciation_percentage        :integer
#  fixed_asset_account            :string
#  fixed_asset_allocation_account :string
#  fixed_asset_expenses_account   :string
#  id                             :integer          not null, primary key
#  label_fra                      :string           not null
#  name                           :jsonb
#  nature                         :string           not null
#  payment_frequency_unit         :string
#  payment_frequency_value        :integer
#  purchasable                    :boolean
#  purchase_account               :string
#  reference_name                 :string           not null
#  sale_account                   :string
#  saleable                       :boolean
#  stock_account                  :string
#  stock_movement_account         :string
#  storable                       :boolean
#
class VariantCategory < ActiveRecord::Base
  include Lexiconable
  include ScopeIntrospection

  scope :of_class_name, -> (*class_names) { where(nature: class_names) }
end
