module Api
  module V2
    module Lexicon
      class ApiPhytosanitaryDataController < Api::V2::BaseController
        before_action :phytosanitary_updated_at, only: [:index]

        private

          def phytosanitary_updated_at
            @updated_at = DatasourceCredit.find_by(datasource: 'phytosanitary')&.updated_at&.l(format: '%d/%m/%Y')
          end

          def phytosanitary_updated_since?(date)
            date && phytosanitary_updated_at && (phytosanitary_updated_at.to_date <= date.to_date)
          end

          def quote(str)
            ApplicationRecord.connection.quote(str)
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
            params.permit(data: %i[id record_checksum]).fetch(:data, [])
          end

          def get_removed_element(elements, table_name:)
            return [] if elements.empty?

            ids = elements.map { |e| "(#{quote(e[:id])})" }.join(',')
            ApplicationRecord.connection.execute("SELECT t.id FROM  (values #{ids}) as t(id) WHERE t.id not in (SELECT id from #{table_name})").to_a
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
