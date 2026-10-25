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
    # Read-only access to the activity productions of a campaign: what is
    # grown (or raised) where, on which surface.
    class ActivityProductionsController < Api::V2::BaseController
      include Api::V2::ReadParams

      # GET /api/v2/activity_productions
      # Lists the activity productions of a campaign, sorted by id.
      #
      # Authentication: required.
      #
      # Query string params:
      # - campaign           [Integer, required] Harvest year (e.g. 2024). Uses
      #                                          `ActivityProduction.of_campaign`
      #                                          (perennial productions belong
      #                                          to several campaigns)
      # - activity_id        [Integer, optional] Id of an activity
      # - cultivable_zone_id [Integer, optional] Id of a cultivable zone
      # - page               [Integer, optional, default 1]
      # - per_page           [Integer, optional, default 50, max 100]
      #
      # Each production exposes its activity, cultivation variety, period,
      # state, net surface area (hectare, computed from the support shape),
      # support (land parcel, animal group...), cultivable zone, and
      # `target_product_ids`: the products attached to the production (support
      # land parcel, plants...), i.e. the `target_id` values found in
      # `GET /api/v2/intervention_records`.
      #
      # Responses:
      # - 200 OK          { "pagination": {...}, "data": [...] }
      # - 400 Bad Request { "errors": [<message>, ...] } on missing or invalid params
      # - 401 Unauthorized
      def index
        errors = []
        harvest_year = parse_campaign(errors, required: true)
        filters = parse_ids({}, errors, :activity_id, :cultivable_zone_id)
        page, per_page = parse_pagination(errors)
        return render_bad_request(errors) if errors.any?

        productions = filter_productions(harvest_year, filters)
        total_elements = productions.count

        @activity_productions = productions
                                  .reorder(:id)
                                  .includes(:activity, :cultivable_zone, :support)
                                  .page(page)
                                  .per(per_page)
                                  .to_a

        @target_product_ids = Product.where(activity_production_id: @activity_productions.map(&:id))
                                     .order(:id)
                                     .pluck(:activity_production_id, :id)
                                     .each_with_object(Hash.new { |h, k| h[k] = [] }) { |(ap_id, id), h| h[ap_id] << id }

        @pagination = pagination_metadata(page: page, per_page: per_page,
                                          elements: @activity_productions.size, total_elements: total_elements)
      end

      private

        def filter_productions(harvest_year, filters)
          campaign = Campaign.find_by(harvest_year: harvest_year)
          return ActivityProduction.none unless campaign

          productions = ActivityProduction.of_campaign(campaign)
          productions = productions.of_activity(filters[:activity_id]) if filters[:activity_id]
          productions = productions.of_cultivable_zone(filters[:cultivable_zone_id]) if filters[:cultivable_zone_id]
          productions
        end
    end
  end
end
