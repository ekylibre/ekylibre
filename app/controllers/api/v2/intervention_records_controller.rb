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
    # Read-only access to recorded (done) interventions, for reporting and
    # question answering. Unlike `GET /api/v2/interventions` (oriented towards
    # the requests assigned to a mobile worker), this endpoint lists what has
    # actually been done on the farm.
    class InterventionRecordsController < Api::V2::BaseController
      DEFAULT_PER_PAGE = 50
      MAX_PER_PAGE = 100

      # GET /api/v2/intervention_records
      # Lists recorded interventions (nature = "record"), excluding rejected
      # ones, most recent first (started_at DESC, then id DESC).
      #
      # Authentication: required.
      #
      # Query string params:
      # - started_after    [String, optional] ISO 8601 date or datetime; keeps
      #                                       interventions with started_at >= value
      # - started_before   [String, optional] ISO 8601 date or datetime; keeps
      #                                       interventions with started_at <= value
      # - campaign         [Integer, optional] Harvest year (e.g. 2024). Uses the
      #                                       intervention <-> campaign link
      #                                       computed from targets' productions
      #                                       (`Intervention.of_campaign`)
      # - procedure_name   [String, optional] Procedo procedure name, e.g. "spraying"
      # - target_id        [Integer, optional] Id of a target product (land parcel,
      #                                       plant, animal group...)
      # - input_product_id [Integer, optional] Id of an input product (matter)
      # - page             [Integer, optional, default 1]
      # - per_page         [Integer, optional, default 50, max 100]
      #
      # Responses:
      # - 200 OK          { "pagination": { elements, page, per_page,
      #                     total_elements, page_count }, "data": [...] }
      # - 400 Bad Request { "errors": [<message>, ...] } on invalid params
      # - 401 Unauthorized
      def index
        errors = []
        filters = parse_filters(errors)
        page, per_page = parse_pagination(errors)
        return render(json: { errors: errors }, status: :bad_request) if errors.any?

        interventions = filter_interventions(filters)
        total_elements = interventions.count

        @interventions = interventions
                           .reorder(started_at: :desc, id: :desc)
                           .includes(targets: :product, inputs: %i[product variant], tools: :product, doers: :product)
                           .page(page)
                           .per(per_page)

        @pagination = {
          elements: @interventions.length,
          page: page,
          per_page: per_page,
          total_elements: total_elements,
          page_count: (total_elements.to_f / per_page).ceil
        }
      end

      private

        def filter_interventions(filters)
          interventions = Intervention.with_nature(:record).where.not(state: :rejected)

          if filters[:started_after]
            interventions = interventions.where(Intervention.arel_table[:started_at].gteq(filters[:started_after]))
          end

          if filters[:started_before]
            interventions = interventions.where(Intervention.arel_table[:started_at].lteq(filters[:started_before]))
          end

          if filters[:campaign]
            campaign = Campaign.find_by(harvest_year: filters[:campaign])
            interventions = campaign ? interventions.of_campaign(campaign) : interventions.none
          end

          interventions = interventions.of_nature(filters[:procedure_name]) if filters[:procedure_name]

          if filters.key?(:target_id)
            target = Product.find_by(id: filters[:target_id])
            interventions = target ? interventions.with_targets(target) : interventions.none
          end

          if filters.key?(:input_product_id)
            input = Product.find_by(id: filters[:input_product_id])
            interventions = if input
                              interventions.where(id: InterventionInput.of_actors(input).select(:intervention_id))
                            else
                              interventions.none
                            end
          end

          interventions
        end

        def parse_filters(errors)
          filters = {}

          %i[started_after started_before].each do |key|
            next if params[key].blank?

            filters[key] = parse_time(params[key])
            errors << "#{key} must be an ISO 8601 date or datetime" if filters[key].nil?
          end

          if params[:campaign].present?
            filters[:campaign] = parse_positive_integer(params[:campaign])
            errors << 'campaign must be a harvest year (e.g. 2024)' if filters[:campaign].nil?
          end

          if params[:procedure_name].present?
            name = params[:procedure_name].to_s
            if Procedo.find(name.to_sym)
              filters[:procedure_name] = name
            else
              errors << "procedure_name is not a known procedure: #{name}"
            end
          end

          %i[target_id input_product_id].each do |key|
            next if params[key].blank?

            filters[key] = parse_positive_integer(params[key])
            errors << "#{key} must be a positive integer" if filters[key].nil?
          end

          filters
        end

        def parse_pagination(errors)
          page = params[:page].present? ? parse_positive_integer(params[:page]) : 1
          errors << 'page must be a positive integer' if page.nil?

          per_page = params[:per_page].present? ? parse_positive_integer(params[:per_page]) : DEFAULT_PER_PAGE
          if per_page.nil? || per_page > MAX_PER_PAGE
            errors << "per_page must be an integer between 1 and #{MAX_PER_PAGE}"
          end

          [page, per_page]
        end

        # @return [ActiveSupport::TimeWithZone, nil]
        def parse_time(value)
          Time.zone.iso8601(value.to_s)
        rescue ArgumentError
          nil
        end

        # @return [Integer, nil]
        def parse_positive_integer(value)
          return nil unless value.to_s =~ /\A\d+\z/

          integer = value.to_i
          integer.positive? ? integer : nil
        end
    end
  end
end
