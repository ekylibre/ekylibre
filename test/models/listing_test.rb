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
# == Table: listings
#
#  conditions   :text
#  created_at   :datetime         not null
#  creator_id   :integer
#  description  :text
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  mail         :text
#  name         :string           not null
#  query        :text
#  root_model   :string           not null
#  source       :text
#  story        :text
#  updated_at   :datetime         not null
#  updater_id   :integer
#

require 'test_helper'

class ListingTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  test 'extract a model column' do
    ListingNode.rebuild!
    listing = Listing.create!(name: 'TestListing', root_model: 'entity')
    root = listing.root
    root.children.create!(
      nature: 'column',
      attribute_name: 'full_name',
      label: root.model.human_attribute_name('full_name')
    )
    listing.reload
    listing.update!({})

    conn = ActiveRecord::Base.connection
    actual = conn.execute(listing.query).values.map(&:compact).reject(&:blank?).flatten

    expected = Entity.order(:full_name).pluck(:full_name)
    assert_equal expected, actual
  end

  test 'extract an associated model column' do
    ListingNode.rebuild!
    listing = Listing.create!(name: 'TestListing', root_model: 'entity')
    root = listing.root
    assoc = root.children
                .create!(
                  nature: 'belongs_to',
                  attribute_name: 'client_account',
                  label: root.model.human_attribute_name('client_account')
                )
    assoc
      .children
      .create!(
        nature: 'column',
        attribute_name: 'name',
        label: assoc.model.human_attribute_name('name')
      )
    listing.reload
    listing.update!({})

    conn = ActiveRecord::Base.connection
    actual = conn.execute(listing.query).values.map(&:compact).reject(&:blank?).flatten

    expected = Entity.joins(:client_account).order('accounts.name').pluck('accounts.name')
    assert_equal expected, actual
  end

  test 'extract a custom field column' do
    create :custom_field, :text, column_name: 'sdqdqsdq_sd_qsq', customized_type: 'Entity'

    ListingNode.rebuild!
    listing = Listing.create!(name: 'TestListing', root_model: 'entity')
    root = listing.root
    root.children.create!(
      nature: 'custom',
      attribute_name: 'sdqdqsdq_sd_qsq',
      label: 'Sdqdqsdq sd qsq'
    )
    listing.reload
    listing.update!({})

    conn = ActiveRecord::Base.connection
    actual = conn.execute(listing.query).values.map(&:compact).reject(&:blank?).flatten

    expected = Entity.pluck(:custom_fields).compact.map { |cf| cf['sdqdqsdq_sd_qsq'] }.sort
    assert_equal expected, actual
  end

  test 'extract an associated custom field column' do
    create :custom_field, :text, column_name: 'account_custom_test', customized_type: 'Account'

    ListingNode.rebuild!
    listing = Listing.create!(name: 'TestListing', root_model: 'entity')
    root = listing.root
    assoc = root.children
                .create!(
                  nature: 'belongs_to',
                  attribute_name: 'client_account',
                  label: root.model.human_attribute_name('client_account')
                )
    assoc
      .children
      .create!(
        nature: 'custom',
        attribute_name: 'account_custom_test',
        label: assoc.model.human_attribute_name('account_custom_test')
      )
    listing.reload
    listing.update!({})

    conn = ActiveRecord::Base.connection
    actual = conn.execute(listing.query).values.map(&:compact).reject(&:blank?).flatten

    expected = Entity.joins(:client_account).pluck('accounts.custom_fields').compact.map { |cf| cf['account_custom_test'] }.sort
    assert_equal expected, actual
  end
end
