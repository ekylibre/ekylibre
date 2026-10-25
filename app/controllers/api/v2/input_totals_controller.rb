# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2014 Brice Texier
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

module Api
  module V2
    # Read-only totals of the inputs consumed by the activity productions of a
    # campaign, e.g. "how much nitrogen on my wheat?" or "how many fungicide
    # passes?".
    class InputTotalsController < Api::V2::BaseController
      include Api::V2::ReadParams

      # GET /api/v2/input_totals
      # Returns one row per (activity production, input product), sorted by
      # activity production id then input product id. See
      # ActivityProductions::InputTotalsCalculation for the imputation rules
      # (recorded interventions of the campaign, split between targets with
      # their imputation ratio) and the unit conversion.
      #
      # Authentication: required.
      #
      # Query string params:
      # - campaign               [Integer, required] Harvest year (e.g. 2024)
      # - activity_production_id [Integer, optional]
      # - activity_id            [Integer, optional]
      # - input_product_id       [Integer, optional] Id of an input product (matter)
      # - procedure_name         [String, optional] Procedo procedure name, e.g. "spraying"
      # - started_after          [String, optional] ISO 8601 date or datetime;
      #                                             keeps interventions with started_at >= value
      # - started_before         [String, optional] ISO 8601 date or datetime;
      #                                             keeps interventions with started_at <= value
      # - page                   [Integer, optional, default 1]
      # - per_page               [Integer, optional, default 50, max 100]
      #
      # Each row exposes:
      # - activity_production { id, name, activity_id } and input { product_id,
      #   name, variant_id, variant_name };
      # - quantity_value / quantity_unit: total consumed quantity in the
      #   reference unit of its dimension (kilogram, liter, unity...);
      # - conditioning_quantity_value / conditioning_unit_name: the same total
      #   in the conditioning unit of the product;
      # - interventions_count: number of interventions (passes);
      # - treated_area_value / treated_area_unit (hectare): sum of the working
      #   zone areas of the production targets, null if unknown;
      # - nitrogen_value / nitrogen_unit (kilogram): units of nitrogen, for
      #   inputs measured by mass whose variant has a nitrogen_concentration,
      #   null otherwise.
      #
      # Responses:
      # - 200 OK          { "pagination": {...}, "data": [...] }
      # - 400 Bad Request { "errors": [<message>, ...] } on missing or invalid params
      # - 401 Unauthorized
      def index
        errors = []
        harvest_year = parse_campaign(errors, required: true)
        filters = parse_ids({}, errors, :activity_production_id, :activity_id, :input_product_id)
        parse_times(filters, errors, :started_after, :started_before)
        procedure_name = parse_procedure_name(errors)
        filters[:procedure_name] = procedure_name if procedure_name
        page, per_page = parse_pagination(errors)
        return render_bad_request(errors) if errors.any?

        campaign = Campaign.find_by(harvest_year: harvest_year)
        rows = campaign ? ActivityProductions::InputTotalsCalculation.new(campaign, filters).compute : []

        @input_totals = rows.slice((page - 1) * per_page, per_page) || []
        @pagination = pagination_metadata(page: page, per_page: per_page,
                                          elements: @input_totals.size, total_elements: rows.size)
      end
    end
  end
end
