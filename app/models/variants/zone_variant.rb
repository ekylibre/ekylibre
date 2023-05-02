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
# == Table: product_nature_variants
#
#  active                    :boolean          default(TRUE), not null
#  category_id               :integer(4)       not null
#  created_at                :datetime         not null
#  creator_id                :integer(4)
#  custom_fields             :jsonb
#  default_quantity          :decimal(19, 4)   default(1), not null
#  default_unit_id           :integer(4)       not null
#  default_unit_name         :string           not null
#  derivative_of             :string
#  france_maaid              :string
#  gtin                      :string
#  id                        :integer(4)       not null, primary key
#  imported_from             :string
#  lock_version              :integer(4)       default(0), not null
#  name                      :string           not null
#  nature_id                 :integer(4)       not null
#  number                    :string           not null
#  pictogram                 :string
#  picture_content_type      :string
#  picture_file_name         :string
#  picture_file_size         :integer(4)
#  picture_updated_at        :datetime
#  provider                  :jsonb
#  providers                 :jsonb
#  reference_name            :string
#  specie_variety            :string
#  stock_account_id          :integer(4)
#  stock_movement_account_id :integer(4)
#  type                      :string           not null
#  unit_name                 :string
#  updated_at                :datetime         not null
#  updater_id                :integer(4)
#  variety                   :string           not null
#  work_number               :string
#
module Variants
  class ZoneVariant < ProductNatureVariant
    def variant_type
      :zone
    end
  end
end
