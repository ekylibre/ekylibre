# frozen_string_literal: true

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
# == Table: deliveries
#
#  annotation              :text
#  created_at              :datetime         not null
#  creator_id              :integer(4)
#  custom_fields           :jsonb
#  driver_id               :integer(4)
#  id                      :integer(4)       not null, primary key
#  lock_version            :integer(4)       default(0), not null
#  mode                    :string
#  number                  :string
#  reference_number        :string
#  responsible_id          :integer(4)
#  started_at              :datetime
#  state                   :string           not null
#  stopped_at              :datetime
#  transporter_id          :integer(4)
#  transporter_purchase_id :integer(4)
#  updated_at              :datetime         not null
#  updater_id              :integer(4)
#

class Delivery < ApplicationRecord
  include Attachable
  include Transitionable
  include Customizable
  acts_as_numbered
  enumerize :mode, in: %i[transporter us third], predicates: true, default: :us
  belongs_to :driver, -> { contacts }, class_name: 'Entity'
  belongs_to :responsible, -> { contacts }, class_name: 'Entity'
  belongs_to :transporter, class_name: 'Entity'
  belongs_to :transporter_purchase, class_name: 'Purchase'
  has_many :parcels, dependent: :nullify
  has_many :receptions, dependent: :nullify
  has_many :shipments, dependent: :nullify
  has_many :tools, class_name: 'DeliveryTool', dependent: :destroy

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :annotation, length: { maximum: 500_000 }, allow_blank: true
  validates :number, :reference_number, length: { maximum: 500 }, allow_blank: true
  validates :started_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  validates :state, presence: true, length: { maximum: 500 }
  validates :stopped_at, timeliness: { on_or_after: ->(delivery) { delivery.started_at || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  # ]VALIDATORS]

  accepts_nested_attributes_for :tools, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :parcels, reject_if: :all_blank, allow_destroy: true

  # States and transitions are handled by the in-house Transitionable
  # component, which replaces the state_machine gem. Transitions live in
  # app/services/delivery/transitions/.
  enumerize :state, in: %i[draft ordered in_preparation prepared started finished], default: :draft, predicates: true,
                    i18n_scope: "models.#{model_name.param_key}.states"

  before_validation do
    self.state ||= :draft
  end

  def status
    draft? ? :stop : finished? ? :go : :caution
  end

  def human_delivery_mode
    mode.text
  end

  def available_parcels
    Parcel.where('(delivery_id = ?) OR ((delivery_id IS ?) AND (state != ?))', id, nil, :given).order(:number)
  end

  def available_shipments
    available_parcels.where(type: 'Shipment')
  end

  def order
    return false unless can_order?

    parcels.each do |parcel|
      parcel.order if parcel.draft?
    end
    super
  end

  def prepare
    return false unless can_prepare?

    parcels.each do |parcel|
      parcel.prepare if parcel.ordered?
    end
    super
  end

  def check
    return false unless can_check?

    parcels.find_each do |parcel|
      # parcel.prepare if parcel.can_prepare?
      parcel.check if parcel.can_check?
    end
    super
  end

  def start
    update_column(:started_at, Time.zone.now)
    super
  end

  def finish
    start if can_start?
    return false unless can_finish?

    update_column(:stopped_at, Time.zone.now)
    parcels.each do |parcel|
      parcel.check if parcel.in_preparation?
      parcel.give if parcel.prepared?
    end
    super
  end

  # Prints human name of current state
  def state_label
    state.text
  end

  # Replaces the method state_machine used to generate. Consumed by the list
  # columns declared with `label_method: :human_state_name`.
  #
  # @return [String] translated name of the current state
  def human_state_name
    state.text
  end

  def all_parcels_almost_prepared?
    parcels.all? { |p| p.prepared? || p.in_preparation? }
  end

  def all_parcels_prepared?
    parcels.all? { |p| p.prepared? || p.given? }
  end
end
