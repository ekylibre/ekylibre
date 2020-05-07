module Api
  module V1
    module Lexicon
      class RegisteredPhytosanitaryProductsController < ApiPhytosanitaryDataController
        def index
          paginated_result(RegisteredPhytosanitaryProduct, order: :id)
        end

        def create
          @removed, @updated = compute_diff(permitted_params, model: RegisteredPhytosanitaryProduct, table_name: table_name)
        end

        private

          # As pkey is not string, need to cast
          def get_removed_element(elements, table_name:)
            return [] if elements.empty?

            ids = elements.map { |e| "(#{quote(e[:id])}::integer)" }.join(',')
            Ekylibre::Record::Base.connection.execute("SELECT t.id FROM  (values #{ids}) as t(id) WHERE t.id not in (SELECT id from #{table_name})").to_a
          end
      end
    end
  end
end
