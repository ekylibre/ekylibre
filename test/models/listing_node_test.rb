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
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: listing_nodes
#
#  attribute_name       :string(255)
#  condition_operator   :string(255)
#  condition_value      :string(255)
#  created_at           :datetime         not null
#  creator_id           :integer
#  depth                :integer          default(0), not null
#  exportable           :boolean          default(TRUE), not null
#  id                   :integer          not null, primary key
#  item_listing_id      :integer
#  item_listing_node_id :integer
#  item_nature          :string(10)
#  item_value           :text
#  key                  :string(255)
#  label                :string(255)      not null
#  lft                  :integer
#  listing_id           :integer          not null
#  lock_version         :integer          default(0), not null
#  name                 :string(255)      not null
#  nature               :string(255)      not null
#  parent_id            :integer
#  position             :integer
#  rgt                  :integer
#  sql_type             :string(255)
#  updated_at           :datetime         not null
#  updater_id           :integer
#


require 'test_helper'

class ListingNodeTest < ActiveSupport::TestCase

end
