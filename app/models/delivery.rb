# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
#  creator_id              :integer
#  custom_fields           :jsonb
#  driver_id               :integer
#  id                      :integer          not null, primary key
#  lock_version            :integer          default(0), not null
#  mode                    :string
#  number                  :string
#  reference_number        :string
#  responsible_id          :integer
#  started_at              :datetime
#  state                   :string           not null
#  stopped_at              :datetime
#  transporter_id          :integer
#  transporter_purchase_id :integer
#  updated_at              :datetime         not null
#  updater_id              :integer
#

class Delivery < Ekylibre::Record::Base
  include Attachable
  include Customizable
  acts_as_numbered
  enumerize :mode, in: [:transporter, :us, :third], predicates: true, default: :us
  belongs_to :driver, -> { contacts }, class_name: 'Entity'
  belongs_to :responsible, -> { contacts }, class_name: 'Entity'
  # belongs_to :storage, class_name: 'Product'
  belongs_to :transporter, class_name: 'Entity'
  belongs_to :transporter_purchase, class_name: 'Purchase'
  has_many :parcels, dependent: :nullify
  has_many :tools, class_name: 'DeliveryTool', dependent: :destroy

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :started_at, :stopped_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_presence_of :state
  # ]VALIDATORS]

  accepts_nested_attributes_for :tools, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :parcels, reject_if: :all_blank, allow_destroy: true

  state_machine :state, initial: :draft do
    state :draft
    state :ordered
    state :in_preparation
    state :prepared
    state :started
    state :finished

    event :order do
      transition draft: :ordered
    end
    event :prepare do
      transition ordered: :in_preparation
    end
    event :check do
      transition in_preparation: :prepared, if: :all_parcels_prepared?
    end
    event :start do
      transition in_preparation: :started
      transition prepared: :started
    end
    event :finish do
      transition in_preparation: :finished
      transition prepared: :finished
      transition started: :finished
    end
    event :cancel do
      transition ordered: :draft
      transition in_preparation: :ordered
      # transition prepared: :in_preparation
      transition started: :prepared
      # transition finished: :started
    end
  end

  before_validation do
    self.state ||= :draft
  end

  def status
    draft? ? :stop : finished? ? :go : :caution
  end

  def human_delivery_mode
    mode.text
  end

  def check
    return false unless can_check?
    parcels.find_each do |parcel|
      # parcel.prepare if parcel.can_prepare?
      parcel.check if parcel.can_check?
    end
    super
  end

  def finish
    return false unless can_finish?
    parcels.each do |parcel|
      parcel.give! if parcel.prepared?
    end
    super
  end

  def all_parcels_in_preparation?
    parcels.all?(&:in_preparation?)
  end

  def all_parcels_prepared?
    parcels.all?(&:prepared?)
  end
end
