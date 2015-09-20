# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
#  access_parameters :json
#  active            :boolean          default(TRUE), not null
#  created_at        :datetime         not null
#  creator_id        :integer
#  embedded          :boolean          default(FALSE), not null
#  host_id           :integer
#  id                :integer          not null, primary key
#  lock_version      :integer          default(0), not null
#  model_euid        :string           not null
#  name              :string           not null
#  product_id        :integer
#  retrieval_mode    :string           not null
#  updated_at        :datetime         not null
#  updater_id        :integer
#  vendor_euid       :string           not null
#

class Sensor < Ekylibre::Record::Base
  enumerize :retrieval_mode, in: [:manual, :automatic], default: :automatic
  belongs_to :product
  belongs_to :host, class_name: 'Product'
  has_many :analyses, class_name: 'Analysis', dependent: :nullify

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_inclusion_of :active, :embedded, in: [true, false]
  validates_presence_of :model_euid, :name, :retrieval_mode, :vendor_euid
  # ]VALIDATORS]

  # TODO: Check parameters presence

  def equipment
    ActiveSensor::Equipment.find(vendor_euid, model_euid)
  end

  # Read sensor indicator and write an analysis
  def retrieve(options = {})
    fail "Unknown equipment: vendor=#{vendor_euid}, model=#{model_euid}" unless equipment

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
        values << { indicator_name: k, value: v } unless v.blank?
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
      attributes[:retrieval_mode] = options[:mode] || :automatic
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
