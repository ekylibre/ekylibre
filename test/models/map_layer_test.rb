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
# == Table: map_layers
#
#  attribution    :string
#  by_default     :boolean          default(FALSE), not null
#  created_at     :datetime         not null
#  creator_id     :integer(4)
#  enabled        :boolean          default(FALSE), not null
#  id             :integer(4)       not null, primary key
#  lock_version   :integer(4)       default(0), not null
#  managed        :boolean          default(FALSE), not null
#  max_zoom       :integer(4)
#  min_zoom       :integer(4)
#  name           :string           not null
#  nature         :string
#  opacity        :integer(4)
#  position       :integer(4)
#  reference_name :string
#  subdomains     :string
#  tms            :boolean          default(FALSE), not null
#  updated_at     :datetime         not null
#  updater_id     :integer(4)
#  url            :string           not null
#
require 'test_helper'

class MapLayerTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  # Add tests here...
end
