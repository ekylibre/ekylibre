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
# == Table: listing_nodes
#
#  attribute_name       :string
#  condition_operator   :string
#  condition_value      :string
#  created_at           :datetime         not null
#  creator_id           :integer(4)
#  depth                :integer(4)       default(0), not null
#  exportable           :boolean          default(TRUE), not null
#  id                   :integer(4)       not null, primary key
#  item_listing_id      :integer(4)
#  item_listing_node_id :integer(4)
#  item_nature          :string
#  item_value           :text
#  key                  :string
#  label                :string           not null
#  lft                  :integer(4)
#  listing_id           :integer(4)       not null
#  lock_version         :integer(4)       default(0), not null
#  name                 :string           not null
#  nature               :string           not null
#  parent_id            :integer(4)
#  position             :integer(4)
#  rgt                  :integer(4)
#  sql_type             :string
#  updated_at           :datetime         not null
#  updater_id           :integer(4)
#

require 'test_helper'

class ListingNodeTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions
  # Add tests here...
end
