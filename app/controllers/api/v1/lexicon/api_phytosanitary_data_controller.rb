module Api
  module V1
    module Lexicon
      class ApiPhytosanitaryDataController < Api::V1::BaseController

        private

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

            ids = elements.map { |e| "('#{e[:id]}')" }.join(',')
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
