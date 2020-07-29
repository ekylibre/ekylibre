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
  class LandParcelsController < Backend::MattersController
    # params:
    #   :q Text search
    def self.list_conditions
      # Neede to handle campaign for perennial activities.
      sql = <<~SQL.gsub(/\n/, ' ')
        SELECT lp.id
        FROM #{LandParcel.table_name} lp
        JOIN #{ActivityProduction.table_name} ap ON lp.id = ap.support_id
        WHERE ap.id IN (
            SELECT activity_production_id
            FROM activity_productions_campaigns
            WHERE campaign_id = ?
          )
      SQL

      code = <<~RUBY
        #{search_conditions(products: %i[name number])} ||= []
        if current_campaign
          c[0] << " AND #{LandParcel.table_name}.id IN (#{sql})"
          c << current_campaign.id
        end
        c
      RUBY
      code.c
    end

    list(conditions: list_conditions, joins: :nature) do |t|
      t.column :name, url: true
      t.column :work_number
      t.column :identification_number
      t.column :net_surface_area, datatype: :measure
      t.column :born_at
      t.column :dead_at
    end

    # List interventions for one production support linked to land parcel
    list(:interventions, conditions: ["#{Intervention.table_name}.nature = ? AND interventions.id IN (SELECT intervention_id FROM activity_productions_interventions WHERE activity_production_id IN (SELECT activity_production_id FROM products WHERE products.id = ?))", 'record', 'params[:id]'.c], order: { created_at: :desc }, line_class: :status) do |t|
      t.column :name, url: true
      t.column :started_at
      t.column :human_working_duration
      t.column :human_target_names
      t.column :human_working_zone_area
      t.column :stopped_at, hidden: true
      t.column :issue, url: true
    end

    list(:plants, conditions: ["#{Plant.table_name}.activity_production_id IN (SELECT activity_production_id FROM products WHERE products.id = ?)", 'params[:id]'.c], order: { name: :asc }, line_class: :status) do |t|
      t.column :name, url: true
      t.column :work_number, hidden: true
      t.column :variety
      t.column :work_name, through: :container, hidden: true, url: true
      t.column :net_surface_area, datatype: :measure
      t.status
      t.column :born_at
      t.column :dead_at
    end

    def index
      notify_land_parcel_creation_warning

      super
    end

    def show
      return unless (plant = find_and_check)

      harvest_advisor = ::Interventions::Phytosanitary::PhytoHarvestAdvisor.new
      @reentry_possible = harvest_advisor.reentry_possible?(plant, Time.zone.now)

      super
    end

    private

      def notify_land_parcel_creation_warning
        warnings = []
        if CultivableZone.count.zero?
          warnings << helpers.link_to(:a_cultivable_zone.tl, backend_cultivable_zones_path)
        end

        if Activity.count.zero?
          warnings << helpers.link_to(:an_activity.tl, backend_activity_productions_path)
        end

        if warnings.any?
          notify_warning_now(:before_add_a_land_parcel_add_a_x_html, x: as_list(warnings), html: true)
        end
      end

      # @param [Array<String>] elements
      # @return [String] HTML representation of a list that contains all the elements in `elements`
      def as_list(elements)
        helpers.content_tag(:ul) do
          elements.map do |element|
            helpers.content_tag(:li, element)
          end.join.html_safe
        end
      end
  end
end
