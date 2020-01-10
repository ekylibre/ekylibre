module Ekylibre
  module Testing
    module Concerns
      module ModelActionTestModule
        extend ActiveSupport::Concern

        module ClassMethods
          def test_model_actions(options = {})
            model = options.fetch(:class, nil) || to_s.split('::').last.slice(0..-5).constantize
            Ekylibre::Testing::FixtureRetriever.new(model)

            test 'validation with empty model should not throw' do
              # TODO: Clear all fixtures ?
              assert_nothing_raised do
                model.new.valid?
              end
            end
          end
        end
      end
    end
  end
end