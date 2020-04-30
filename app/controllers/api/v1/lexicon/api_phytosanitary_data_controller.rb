module Api
  module V1
    module Lexicon
      class ApiPhytosanitaryDataController < Api::V1::BaseController

        private

          def quote(str)
            ActiveRecord::Base.connection.quote(str)
          end

          def paginated_result(model, order: nil)
            if params.key?(:paginate)
              per_page = [1000, params.fetch(:per_page, 100).to_i].min
              asked_page = params.fetch(:page, 1).to_i

              total_elements = model.count
              page_count = (total_elements.to_f / per_page).ceil

              page = [asked_page, page_count].min

              all_models = model.all
              all_models = all_models.order(order) if order.present?

              @data = all_models.limit(per_page).offset(per_page * (page - 1))

              @pagination = {
                elements: @data.count,
                page: page,
                total_elements: total_elements,
                page_count: page_count
              }.to_struct
            else
              _, @data = compute_diff([], model: model, table_name: table_name)
            end
          end

          def compute_diff(elements, model:, table_name:)
            removed = get_removed_element(elements, table_name: table_name)
            updated_or_inserted_elements = get_updated_or_inserted_elements(elements, model: model)

            [removed, updated_or_inserted_elements]
          end

          def permitted_params
            params.permit(data: [:id, :record_checksum]).fetch(:data, [])
          end

          def get_removed_element(elements, table_name:)
            return [] if elements.empty?

            ids = elements.map { |e| "(#{quote(e[:id])})" }.join(',')
            Ekylibre::Record::Base.connection.execute("SELECT t.id FROM  (values #{ids}) as t(id) WHERE t.id not in (SELECT id from #{table_name})").to_a
          end

          def get_updated_or_inserted_elements(elements, model:)
            return model.all if elements.empty?

            values = elements.flat_map { |e| [e[:id], e[:record_checksum]] }

            bind_params = ['(?, ?)'] * elements.length
            model.where("(id, record_checksum) NOT IN (#{bind_params.join(', ')})", *values)
          end

          def table_name
            controller_name.to_s
          end
      end
    end
  end
end
