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
# == Table: product_natures
#
#  abilities_list            :text
#  active                    :boolean          default(FALSE), not null
#  created_at                :datetime         not null
#  creator_id                :integer
#  custom_fields             :jsonb
#  derivative_of             :string
#  derivatives_list          :text
#  description               :text
#  evolvable                 :boolean          default(FALSE), not null
#  frozen_indicators_list    :text
#  id                        :integer          not null, primary key
#  imported_from             :string
#  linkage_points_list       :text
#  lock_version              :integer          default(0), not null
#  name                      :string           not null
#  number                    :string           not null
#  picture_content_type      :string
#  picture_file_name         :string
#  picture_file_size         :integer
#  picture_updated_at        :datetime
#  population_counting       :string           not null
#  provider                  :jsonb
#  reference_name            :string
#  subscribing               :boolean          default(FALSE), not null
#  subscription_days_count   :integer          default(0), not null
#  subscription_months_count :integer          default(0), not null
#  subscription_nature_id    :integer
#  subscription_years_count  :integer          default(0), not null
#  type                      :string           not null
#  updated_at                :datetime         not null
#  updater_id                :integer
#  variable_indicators_list  :text
#  variety                   :string           not null
#
module VariantTypes
  class AnimalType < ProductNature; end
end
