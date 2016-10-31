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

module Backend
  class SensorsController < Backend::BaseController
    manage_restfully

    unroll

    list do |t|
      t.action :edit
      t.action :destroy
      t.column :active
      t.column :name, url: true
      t.column :retrieval_mode
      t.column :vendor_euid
      t.column :model_euid
      t.column :product, url: true
      t.column :embedded
      t.column :host, url: true
    end

    list :analyses, model: :analysis, conditions: { sensor_id: 'params[:id]'.c } do |t|
      t.column :number, url: true
      t.column :nature
      t.column :analysed_at
      t.column :retrieval_status
      t.column :retrieval_message
      t.column :sampling_temporal_mode
    end

    def models
      vendor_euid = params[:vendor_euid]
      models = []
      if vendor_euid
        models = ActiveSensor::Equipment.equipments_of(vendor_euid).collect do |equipment|
          [equipment.label, equipment.model]
        end
      end
      respond_to do |format|
        format.json { render json: models }
      end
    end

    # Updates details and settings in form
    def detail
      @equipment = ActiveSensor::Equipment.find!(params[:vendor_euid], params[:model_euid])

      # Load existing resource for edit
      @sensor = Sensor.find(params[:id]) if params[:id].present?

      respond_to do |format|
        format.js
      end
    end

    def retrieve
      @sensor = find_and_check
      return unless @sensor
      # SensorReadingJob.perform_later(id: @sensor.id, started_at: Time.now, stopped_at: Time.now)
      @sensor.retrieve(started_at: Time.zone.now - 1.hour, stopped_at: Time.zone.now)
      redirect_to params[:redirect] || { action: :show, id: params[:id] }
    end

    def last_locations
      @geolocations = Sensor
                      .includes(:analyses)
                      .find_each
                      .map do |sensor|
        last_analysis = sensor.analyses.last
        if last_analysis.present? && (geoloc = last_analysis.geolocation)
          [sensor.id, geoloc && JSON(geoloc.to_json)]
        end
      end
                      .compact
                      .to_h
      render json: @geolocations.to_json
    end
  end
end
