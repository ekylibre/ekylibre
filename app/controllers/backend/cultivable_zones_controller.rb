# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2013 David Joulin, Brice Texier
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
  class CultivableZonesController < Backend::BaseController
    manage_restfully(t3e: { name: :name })

    respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

    unroll

    list do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :name, url: true
      t.column :work_number
      t.column :human_shape_area, datatype: :measure
      t.column :edge_length, datatype: :measure
      # FIXME: Remove use of "_name" for nomen columns
      t.column :production_system_name
      t.column :farmer, url: true
      t.column :owner, url: true
      t.column :city_name, hidden: true
      t.column :cap_number, hidden: true
    end

    # content production on current cultivable land parcel
    list(:productions, model: :activity_productions, conditions: { cultivable_zone_id: 'params[:id]'.c }, order: 'started_on DESC') do |t|
      t.column :name, url: true
      t.column :activity, url: true
      t.column :support, url: true
      t.column :usage
      t.column :grains_yield, datatype: :measure
      t.column :started_on
      t.column :stopped_on
    end

    # Show one cultivable zone with params_id
    def show
      return unless @cultivable_zone = find_and_check

      t3e @cultivable_zone
      # Handled before respond_with: the PDF format used to fall through to
      # ActionController::Responder#to_pdf (lib/reporting.rb) and be rendered by
      # Jasper. It now goes through a Printers::* class and an ODT template.
      if request.format.pdf?
        return unless template = find_and_check(:document_template, params[:template])

        PrinterJob.perform_later('Printers::CultivableZoneSheetPrinter', template: template,
                                 cultivable_zone: @cultivable_zone,
                                 perform_as: current_user)
        notify_success(:document_in_preparation)
        return redirect_back(fallback_location: { action: :index })
      end

      respond_with(@cultivable_zone, methods: %i[shape_svg cap_number human_shape_area],
                                     include: [
                                       { activity_productions: {
                                         methods: %i[name implanted_at harvested_at],
                                         include: {
                                           interventions: {
                                             methods: %i[started_at stopped_at status name human_working_duration human_working_zone_area human_actions_names human_input_quantity_names],
                                             include: {}
                                           }
                                         }
                                       } }
                                     ], procs: proc { |options| options[:builder].tag!(:url, backend_cultivable_zone_url(@cultivable_zone)) })
    end
  end
end
