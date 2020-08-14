module Ekylibre
  module Testing
    module Minitest
      module Profile
        class RunnableFilter
          attr_reader :time_provider, :limit, :selector

          def initialize(time_provider:, limit:, selector:)
            @time_provider = time_provider
            @limit = limit
            @selector = selector
          end

          def keep?(fq_name)
            time = time_provider.time_of(fq_name)
            if time.nil?
              true
            elsif selector == :lower
              time <= limit
            elsif selector == :higher
              time >= limit
            else # Selector is not handled, this should not happen but degrade gracefully
              puts "Invalid selector used."

              true
            end
          end
        end
      end
    end
  end
end