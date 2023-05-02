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
# == Table: wine_incoming_harvests
#
#  additional_informations :jsonb            default("{}")
#  analysis_id             :integer(4)
#  campaign_id             :integer(4)       not null
#  created_at              :datetime         not null
#  creator_id              :integer(4)
#  description             :text
#  id                      :integer(4)       not null, primary key
#  lock_version            :integer(4)       default(0), not null
#  number                  :string
#  quantity_unit           :string           not null
#  quantity_value          :decimal(19, 4)   not null
#  received_at             :datetime         not null
#  ticket_number           :string
#  updated_at              :datetime         not null
#  updater_id              :integer(4)
#
require 'test_helper'

class WineIncomingHarvestTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  setup do
    @wine_incoming_harvest = create(:wine_incoming_harvest)
  end

  test 'create wine incoming harvest' do
    assert_equal WineIncomingHarvest.last, @wine_incoming_harvest
  end

  test 'create plants linked to wine incoming harvest' do
    wine_incoming_harvest = create(:wine_incoming_harvest, :with_wine_incoming_harvest_plants)
    assert_equal WineIncomingHarvestPlant.last, wine_incoming_harvest.plants.last
  end

  test 'create presses linked to wine incoming harvest ' do
    wine_incoming_harvest = create(:wine_incoming_harvest, :with_wine_incoming_harvest_presses)
    assert_equal WineIncomingHarvestPress.last, wine_incoming_harvest.presses.last
  end

  test 'create storages linked to wine incoming harvest ' do
    wine_incoming_harvest = create(:wine_incoming_harvest, :with_wine_incoming_harvest_storages)
    assert_equal WineIncomingHarvestStorage.last, wine_incoming_harvest.storages.last
  end
end
