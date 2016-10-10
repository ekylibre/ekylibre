# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
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

module Backend
  class InspectionsController < Backend::BaseController
    include InspectionViewable

    manage_restfully sampled_at: 'Time.zone.now'.c

    unroll

    list do |t|
      t.action :edit
      t.action :destroy
      t.action :export, on: :both
      t.column :number, url: true
      t.column :activity, url: true
      t.column :product, url: true
      t.column :sampled_at, datatype: :datetime
      # t.column :implanter_rows_number
      # t.column :implanter_working_width
    end

    def export
      inspections = find_inspections
      respond_to do |format|
        format.html
        format.ods do
          send_data(
            inspections_to_ods_export(inspections).bytes,
            filename: "[#{Time.zone.now.l}] #{Inspection.model_name.human}.ods".underscore
          )
        end
      end
    end

    private

    def find_inspections
      inspection_ids = params[:id].split(',')
      inspections = Inspection.where(id: inspection_ids)
      unless inspections.any?
        notify_error :no_inspections_given
        redirect_to(params[:redirect] || { action: :index })
        return nil
      end
      inspections
    end

    # FIXME
    # Not satisfied that the code is here instead of somewhere else but I can't
    # really figure out where it should be.
    #
    # Maybe an Exporter ? A Presenter ? Something along those lines ?
    def inspections_to_ods_export(inspections)
      require 'odf/spreadsheet'
      output = ODF::Spreadsheet.new
      output.instance_eval do
        office_style :important, family: :cell do
          property :text, 'font-weight': :bold, 'font-size': '11px'
        end
        office_style :bold, family: :cell do
          property :text, 'font-weight': :bold
        end

        inspections.group_by(&:activity).each do |activity, a_inspections|
          dimensions = [:items_count, :net_mass].select { |dim| a_inspections.any? { |i| i.measure_grading(dim) } }

          table activity.name do
            row do
              cell Plant.model_name.human,                    style: :important
              cell Plant.human_attribute_name(:variety),      style: :important
              cell Inspection.human_attribute_name(:number),  style: :important
              cell InspectionCalibration.model_name.human,    style: :important
              dimensions.each do |dimension|
                cell Inspection.human_attribute_name("total_#{dimension}"), style: :important
              end
            end

            a_inspections.group_by(&:product).each do |plant, p_inspections|
              p_inspections.each do |inspection|
                inspection.calibrations.each do |calib|
                  row do
                    cell plant.name
                    cell plant.variety.capitalize
                    cell inspection.number
                    cell calib.nature_name
                    dimensions.each do |dimension|
                      next cell('-') unless inspection.measure_grading(dimension)
                      cell calib.projected_total(dimension).round(0).l(precision: 0)
                    end
                  end
                end
              end
            end
          end
        end
      end
      output
    end
  end
end
