module Ekylibre
  module Testing
    module Concerns
      module FixturesModule
        extend ActiveSupport::Concern

        included do
          # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
          fixtures :all

          def fixture_file(*levels)
            fixture_files_path.join(*levels)
          end

          def fixture_files_path
            self.class.fixture_files_path
          end

          def with_fixtures?
            true
          end
        end

        module ClassMethods
          def fixture_files_path
            Rails.root.join('test', 'fixture-files')
          end

          # Returns ID of the given label
          def identify(label)
            # ActiveRecord::FixtureSet.identify(label)
            elements = label.to_s.split('_')
            model = elements[0...-1].join('_').classify.constantize
            @@fixtures ||= {}
            @@fixtures[model.table_name] ||= YAML.load_file(Rails.root.join('test', 'fixtures', "#{model.table_name}.yml"))
            unless attrs = @@fixtures[model.table_name][label.to_s]
              raise "Unknown fixture #{label}"
            end

            attrs['id'].to_i
          end
        end
      end
    end
  end
end
