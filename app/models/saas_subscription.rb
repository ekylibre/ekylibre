# frozen_string_literal: true

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
# == Table: subscriptions
#
#  address_id     :integer
#  created_at     :datetime         not null
#  creator_id     :integer
#  custom_fields  :jsonb
#  description    :text
#  id             :integer          not null, primary key
#  lock_version   :integer          default(0), not null
#  nature_id      :integer
#  number         :string
#  parent_id      :integer
#  quantity       :integer          not null
#  sale_item_id   :integer
#  started_on     :date             not null
#  stopped_on     :date             not null
#  subscriber_id  :integer
#  suspended      :boolean          default(FALSE), not null
#  swim_lane_uuid :uuid             not null
#  updated_at     :datetime         not null
#  updater_id     :integer
#

class SaasSubscription < ApplicationRecord
  include Providable
  enumerize :status, in: %i[active past_due unpaid canceled incomplete incomplete_expired trialing], predicates: true
  belongs_to :partner, class_name: 'Entity'
  belongs_to :entity_payment_method, class_name: 'EntityPaymentMethod'
  belongs_to :entity, class_name: 'Entity'
  belongs_to :catalog_item, class_name: 'CatalogItem', inverse_of: :saas_subscriptions
  has_one :variant, through: :catalog_item, class_name: 'ProductNatureVariant'

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  # ]VALIDATORS]
  scope :active, -> { where('canceled_at IS NULL AND stopped_at IS NULL') }
  scope :started_between, ->(started_at, stopped_at) { where('started_at BETWEEN ? AND ?', started_at, stopped_at) }
  scope :stopped_between, ->(started_at, stopped_at) { where('(stopped_at BETWEEN ? AND ?) OR (canceled_at BETWEEN ? AND ?)', started_at, stopped_at, started_at, stopped_at) }
  scope :active_up_to, ->(stopped_at) { where('(canceled_at IS NULL AND stopped_at IS NULL) AND started_at <= ?', stopped_at) }
  scope :of_catalog_item, ->(catalog_item) { where(catalog_item: catalog_item) }

  before_validation do
    self.started_at ||= Time.zone.now
    self.name ||= "#{self.tenant_name&.lower} | #{self.entity.full_name&.lower}"
  end

end
