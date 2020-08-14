module Ekylibre
  module Testing
    module Minitest
      module Profile
        class TimeProvider
          class << self
            # @param [Pathname] profiles_file
            # @return [RecordedTimesProvider]
            def from(profiles_file)
              times = {}

              if profiles_file.exist?
                times = JSON.parse(profiles_file.read)
                            .map { |p| [p.fetch('name'), p.fetch('duration')] }
                            .to_h
              end

              new(times)
            end
          end

          # @param [Hash<String, Numeric>] times
          def initialize(times)
            @times = times
          end

          # @param [String] name
          # @return [Numeric, nil]
          def time_of(name)
            @times[name]
          end

          def values
            @times.values
          end
        end
      end
    end
  end
end