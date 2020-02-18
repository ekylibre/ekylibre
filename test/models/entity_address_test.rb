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
# == Table: entity_addresses
#
#  by_default          :boolean          default(FALSE), not null
#  canal               :string           not null
#  coordinate          :string           not null
#  created_at          :datetime         not null
#  creator_id          :integer
#  deleted_at          :datetime
#  entity_id           :integer          not null
#  id                  :integer          not null, primary key
#  lock_version        :integer          default(0), not null
#  mail_auto_update    :boolean          default(FALSE), not null
#  mail_country        :string
#  mail_geolocation    :geometry({:srid=>4326, :type=>"st_point"})
#  mail_line_1         :string
#  mail_line_2         :string
#  mail_line_3         :string
#  mail_line_4         :string
#  mail_line_5         :string
#  mail_line_6         :string
#  mail_postal_zone_id :integer
#  name                :string
#  thread              :string
#  updated_at          :datetime         not null
#  updater_id          :integer
#

require 'test_helper'

class EntityAddressTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions
  test 'presence of canal scopes' do
    for canal in EntityAddress.canal.values
      scope_name = canal.to_s.pluralize.to_sym
      assert EntityAddress.respond_to?(scope_name), "EntityAddress must have a scope #{scope_name}"
      scope_name = ('own_' + canal.to_s.pluralize).to_sym
      assert EntityAddress.respond_to?(scope_name), "EntityAddress must have a scope #{scope_name}"
      # TODO: Check that scope works
    end
  end
end
