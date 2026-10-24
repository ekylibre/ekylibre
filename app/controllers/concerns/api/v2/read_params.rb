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
    # Shared query string parsing for the read-only reporting endpoints
    # (intervention_records, activity_productions, input_totals).
    #
    # Parsers append English messages to an `errors` array instead of raising,
    # so that all invalid parameters are reported at once in a
    # 400 { "errors": [...] } response.
    module ReadParams
      extend ActiveSupport::Concern

      DEFAULT_PER_PAGE = 50
      MAX_PER_PAGE = 100

      private

        def render_bad_request(errors)
          render(json: { errors: errors }, status: :bad_request)
        end

        # @return [Array(Integer, Integer)] page and per_page (nil when invalid)
        def parse_pagination(errors)
          page = params[:page].present? ? parse_positive_integer(params[:page]) : 1
          errors << 'page must be a positive integer' if page.nil?

          per_page = params[:per_page].present? ? parse_positive_integer(params[:per_page]) : DEFAULT_PER_PAGE
          if per_page.nil? || per_page > MAX_PER_PAGE
            errors << "per_page must be an integer between 1 and #{MAX_PER_PAGE}"
          end

          [page, per_page]
        end

        # Same envelope as the lexicon endpoints.
        def pagination_metadata(page:, per_page:, elements:, total_elements:)
          {
            elements: elements,
            page: page,
            per_page: per_page,
            total_elements: total_elements,
            page_count: (total_elements.to_f / per_page).ceil
          }
        end

        # Parses the `campaign` param (harvest year).
        # @return [Integer, nil]
        def parse_campaign(errors, required: false)
          if params[:campaign].blank?
            errors << 'campaign is required (harvest year, e.g. 2024)' if required
            return nil
          end

          year = parse_positive_integer(params[:campaign])
          errors << 'campaign must be a harvest year (e.g. 2024)' if year.nil?
          year
        end

        # Parses optional positive integer params (ids) into `filters`.
        def parse_ids(filters, errors, *keys)
          keys.each do |key|
            next if params[key].blank?

            filters[key] = parse_positive_integer(params[key])
            errors << "#{key} must be a positive integer" if filters[key].nil?
          end
          filters
        end

        # Parses optional ISO 8601 params into `filters`.
        def parse_times(filters, errors, *keys)
          keys.each do |key|
            next if params[key].blank?

            filters[key] = parse_time(params[key])
            errors << "#{key} must be an ISO 8601 date or datetime" if filters[key].nil?
          end
          filters
        end

        # @return [String, nil] the procedure name if known by Procedo
        def parse_procedure_name(errors)
          return nil if params[:procedure_name].blank?

          name = params[:procedure_name].to_s
          return name if Procedo.find(name.to_sym)

          errors << "procedure_name is not a known procedure: #{name}"
          nil
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
