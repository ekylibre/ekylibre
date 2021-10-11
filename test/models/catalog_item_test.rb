# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2021 Ekylibre SAS
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
# == Table: catalog_items
#
#  all_taxes_included     :boolean          default(FALSE), not null
#  amount                 :decimal(19, 4)   not null
#  catalog_id             :integer          not null
#  commercial_description :text
#  commercial_name        :string
#  created_at             :datetime         not null
#  creator_id             :integer
#  currency               :string           not null
#  id                     :integer          not null, primary key
#  lock_version           :integer          default(0), not null
#  name                   :string           not null
#  reference_tax_id       :integer
#  updated_at             :datetime         not null
#  updater_id             :integer
#  variant_id             :integer          not null
#
require 'test_helper'

class CatalogItemTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  test 'temporality is automatically set upon validations for items sharing the same catalog, variant and unit' do
    item_one = create :catalog_item, started_at: Date.new(2019, 1, 1)

    assert_nil item_one.stopped_at

    item_two = create :catalog_item, started_at: Date.new(2018, 1, 1), catalog: item_one.catalog, variant: item_one.variant

    assert_nil item_one.stopped_at
    assert_equal item_one.started_at - 1.minute, item_two.stopped_at

    item_three = create :catalog_item, started_at: Date.new(2020, 1, 1), catalog: item_one.catalog, variant: item_one.variant

    assert_nil item_three.stopped_at
    assert_equal item_three.started_at - 1.minute, item_one.reload.stopped_at
  end
end
