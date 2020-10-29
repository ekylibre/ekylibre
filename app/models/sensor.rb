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
# == Table: sensors
#
#  access_parameters    :json
#  active               :boolean          default(TRUE), not null
#  battery_level        :decimal(19, 4)
#  created_at           :datetime         not null
#  creator_id           :integer
#  custom_fields        :jsonb
#  embedded             :boolean          default(FALSE), not null
#  euid                 :string
#  host_id              :integer
#  id                   :integer          not null, primary key
#  last_transmission_at :datetime
#  lock_version         :integer          default(0), not null
#  model_euid           :string
#  name                 :string           not null
#  partner_url          :string
#  product_id           :integer
#  retrieval_mode       :string           not null
#  token                :string
#  updated_at           :datetime         not null
#  updater_id           :integer
#  vendor_euid          :string
#

class Sensor < Ekylibre::Record::Base
  include Attachable
  include Customizable
  enumerize :retrieval_mode, in: %i[requesting listening integration], default: :requesting, predicates: true
  belongs_to :product
  belongs_to :host, class_name: 'Product'
  has_many :analyses, class_name: 'Analysis', dependent: :nullify
  has_many :alerts, dependent: :destroy

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :active, :embedded, inclusion: { in: [true, false] }
  validates :battery_level, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :euid, :model_euid, :partner_url, :token, :vendor_euid, length: { maximum: 500 }, allow_blank: true
  validates :last_transmission_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :name, presence: true, length: { maximum: 500 }
  validates :retrieval_mode, presence: true
  # ]VALIDATORS]
  validates :name, uniqueness: true
  validates :token, presence: { if: :listening? }
  validates :vendor_euid, :model_euid, presence: { unless: :listening? }

  # TODO: Check parameters presence

  before_validation do
    if token.blank?
      self.token = User.give_password(16, :normal)
      while self.class.where(token: token).where.not(id: id).any?
        self.token = User.give_password(16, :normal)
      end
    end
  end

  def equipment
    ActiveSensor::Equipment.find(vendor_euid, model_euid)
  end

  def alert_status
    return :go if alerts.joins(:phases).all? { |alert| alert.level.zero? }
    return :stop if alerts.joins(:phases).none? { |alert| alert.level.zero? }
    :caution
  end

  def alert_on?(alert_nature)
    alert = alerts.find_by(nature: alert_nature)
    alert.present? && alert.level > 0
  end

  # Read sensor indicator and write an analysis
  def retrieve(options = {})
    return if listening?
    raise "Unknown equipment: vendor=#{vendor_euid}, model=#{model_euid}" unless equipment

    connection = equipment.connect(access_parameters)

    results = connection.retrieve(options)
    attributes = {
      retrieval_status: results[:status]
    }
    attributes[:nature] = results[:nature] || :sensor_analysis
    if results[:status].to_s == 'ok'
      # Indicators
      values = []
      results[:values].each do |k, v|
        values << { indicator_name: k, value: v } if v.present?
      end
      attributes.update(
        sampled_at: options[:started_at],
        analysed_at: options[:stopped_at],
        stopped_at: options[:stopped_at],
        geolocation: results[:geolocation],
        sampling_temporal_mode: results[:sampling_temporal_mode],
        items_attributes: values
      )
    else
      attributes[:retrieval_message] = results[:message]
    end
    analysis = analyses.create!(attributes)
    if analysis.status_changed? && options[:background]
      if analysis.ok? && analysis.previous
        notify(:sensor_has_been_fixed, { name: name }, level: :success)
      else
        notify(:sensor_is_out_of_service, { name: name, message: attributes[:retrieval_message] }, level: :error)
      end
    end
    analysis
  rescue => e
    # save failure
    # NOPE
    raise e
    analysis = analyses.create!(retrieval_status: :internal_error, retrieval_message: e.message, nature: :sensor_analysis, sampled_at: Time.now)
    if options[:background] && analysis.status_changed?
      notify_error(:sensor_reading_failed, { name: name, message: e.message }, level: :error)
    end
    analysis
  end

  class << self
    # Get all sensors and retrieve data
    def retrieve_all(options = {})
      attributes = { active: true }
      attributes[:retrieval_mode] = options[:mode] || :listening
      default_interval = 1.hour
      options[:stopped_at] ||= Time.zone.now
      options[:started_at] ||= options[:stopped_at] - default_interval
      where(attributes).find_each do |sensor|
        sensor.retrieve(options)
      end
    end
  end

  # Notify concerned people about issues on sensors
  # For now, administrators are notified.
  def notify(message, interpolations = {}, options = {})
    User.notify_administrators(message, interpolations, options.merge(target: self))
  end
end
