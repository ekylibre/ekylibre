module Ekylibre
  module Testing
    module Minitest
      module Profile
        module FilterModule
          def self.included(mod)
            mod.singleton_class.send(:prepend, KlassMethods)
          end

          module KlassMethods
            def runnable_methods
              super()
                .select { |runnable| filter.keep?("#{self}##{runnable}") }
            end

            private def filter
              ::Minitest.ekylibre_plugin
                        .filter
            end
          end
        end
      end
    end
  end
end