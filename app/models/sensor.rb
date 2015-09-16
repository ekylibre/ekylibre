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
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_inclusion_of :active, :embedded, in: [true, false]
  validates_presence_of :model_euid, :name, :retrieval_mode, :vendor_euid
  # ]VALIDATORS]
  belongs_to :product
  belongs_to :host, class_name: 'Product', foreign_key: :host_id
  has_many :analyses, class_name: 'Analysis'


  def equipment
    ActiveSensor::Equipment.find(vendor_euid, model_euid)
  end

  class << self
    #Get all sensors and retrieve data
    def retrieve_all(options = {})

      default_interval = 1.hour

      options[:started_at] ||= Time.now - default_interval
      options[:stopped_at] ||= Time.now
      options[:mode] ||= :automatic
      options[:active] ||= true

      # attributes
      attributes = {}
      attributes[:retrieval_mode] = options[:mode] # manual / automatic
      attributes[:active] = options[:active]
      attributes[:id] = options[:id] unless options[:id].nil?

      where(attributes).find_each do |sensor|

        begin
          connection = ActiveSensor::Equipment.get(sensor.vendor_euid, sensor.model_euid, sensor.access_parameters)

          results = connection.retrieve(options)

          time = results.delete(:time)

          # Charta Geometry
          geolocation = results.delete(:geolocation)

          attributes = {}
          attributes[:items_attributes] = []

          attributes[:sampling_temporal_mode] = results.delete(:sampling_temporal_mode)

          #Indicators
          results.each do |k, v|
            n = Nomen::Indicator.find(k)
            attributes[:items_attributes] << { indicator_name: n.name, indicator_datatype: n.datatype, value: v } unless v.nil?
          end

          attributes[:state] = 'ok'
          attributes[:nature] = 'meteorological_analysis'
          attributes[:sampled_at] = options[:started_at]
          attributes[:analysed_at] = options[:started_at]
          attributes[:stopped_at] = options[:stopped_at]

          # save
          analysis = sensor.analyses.new(attributes.except(:items_attributes))
          analysis.attributes = attributes
          analysis.geolocation = geolocation
          analysis.save!

        rescue => e
          # save failure
          sensor.analyses.create!(error_explanation: e.message, state: 'error', nature: 'meteorological_analysis', sampled_at: Time.now)
        end
      end
    end
  end

end
