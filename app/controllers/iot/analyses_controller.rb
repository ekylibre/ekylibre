# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2015 Brice Texier
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

module Iot
  class AnalysesController < Iot::BaseController
    def create
      report = params
      attributes = {}

      # Get sampled_at
      attributes[:sampled_at] = report.delete(:at).to_time if report[:at]

      # Get geolocation expected as WGS84
      if report[:latlon]
        attributes[:geolocation] = Charta.new_point(*report.delete(:latlon))
      end

      # Get indicators
      items = []
      report[:items] ||= {}
      report[:items].each do |name, value|
        indicator = Nomen::Indicator.find(name)
        unless indicator
          render json: { message: "Indicator #{name} is unacceptable" }, status: :not_acceptable
          return false
        end
        type = indicator.datatype.to_sym
        case type
        when :integer
          value = value.to_i
        when :decimal
          value = value.to_d
        when :boolean
          value = %w[yes true 1 ok].include?(value.downcase)
        when :choice
          unless indicator.choices.include?(value)
            render json: { message: "Indicator choice #{value} is unacceptable." }, status: :not_acceptable
            return false
          end
          value
        when :measure
          value = Measure.new(value)
        when :point
          value = Charta.new_point(*value)
        when :geometry
          value = Charta.new_geometry(value)
        end
        items << { indicator_name: name, value: value }
      end
      attributes[:items_attributes] = items
      attributes[:nature] = params[:type] || :sensor_analysis

      # Create analyses
      analysis = @sensor.analyses.create!(attributes)

      render json: { message: 'ok' }
    end
  end
end
