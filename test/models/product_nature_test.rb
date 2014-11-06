# = Informations
#
# == License
#
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
#  abilities_list           :text
#  active                   :boolean          not null
#  category_id              :integer          not null
#  created_at               :datetime         not null
#  creator_id               :integer
#  derivative_of            :string(120)
#  derivatives_list         :text
#  description              :text
#  evolvable                :boolean          not null
#  frozen_indicators_list   :text
#  id                       :integer          not null, primary key
#  linkage_points_list      :text
#  lock_version             :integer          default(0), not null
#  name                     :string(255)      not null
#  number                   :string(30)       not null
#  picture_content_type     :string(255)
#  picture_file_name        :string(255)
#  picture_file_size        :integer
#  picture_updated_at       :datetime
#  population_counting      :string(255)      not null
#  reference_name           :string(120)
#  updated_at               :datetime         not null
#  updater_id               :integer
#  variable_indicators_list :text
#  variety                  :string(120)      not null
#
require 'test_helper'

class ProductNatureTest < ActiveSupport::TestCase

end
