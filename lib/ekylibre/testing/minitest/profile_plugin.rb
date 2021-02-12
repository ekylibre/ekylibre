module Ekylibre
  module Testing
    module Minitest
      # This class is a plugin for minitest that allows to separate the test executed by an expected duration that is "guessed" using data
      # recorded from previous runs. _Tests that don't have profiling data are always run._
      # The filtering is done by prepending a module into the Minitest:Test singleton class to override the method that, for each test suite,
      # lists the runnables methods (public instance methods starting by 'test_')
      class ProfilePlugin
        DEFAULT_LIMIT = 0.4
        VALID_SELECTS = %i[lower higher].freeze

        class << self
          def register(options)
            if options[:ekylibre][:enabled]
              puts "Enabling ekylibre minitest plugin"

              # By defining the property this way, if the plugin is not enabled, no addition id done to Minitest aside from the two plugins methods.
              ::Minitest.singleton_class.send(:attr_accessor, :ekylibre_plugin)
              ::Minitest.ekylibre_plugin = build(options[:ekylibre].to_struct)
            end
          end

          def build(options)
            time_provider = ::Ekylibre::Testing::Minitest::Profile::TimeProvider.from(options.profiles_file)

            limit = compute_limit(times: time_provider.values, percent: options.limit)

            puts <<~TEXT
              Setting test execution time limit for filter to #{limit} seconds and execute tests for which we expect #{options.select} duration.
              Tests without profiling information in #{options.profiles_file} are always run.
            TEXT

            new(
              time_provider: time_provider,
              limit: limit,
              filter: ::Ekylibre::Testing::Minitest::Profile::RunnableFilter.new(time_provider: time_provider, limit: limit, selector: options.select)
            )
          end

          def parse_options(opts, options)
            options[:ekylibre] = {
              enabled: false,
              limit: DEFAULT_LIMIT,
              select: :lower,
              profiles_file: Rails.root.join('test', 'fixture-files', 'profiles.json')
            }

            opts.on('--ekylibre') do
              options[:ekylibre][:enabled] = true
            end

            opts.on('--profile-limit=LIMIT') do |v|
              if v < 0 || v > 1
                raise ArgumentError.new("Invalid value for --profile-limit. Got #{v} when it should be between 0 and 1")
              end

              options[:ekylibre][:limit] = [1, v].min
            end

            opts.on('--profile-select=PROFILE') do |v|
              value = v.to_sym

              if VALID_SELECTS.include?(value)
                options[:ekylibre][:select] = value
              else
                raise ArgumentError.new("Invalid value for --profile-select. Got #{value} but expected any of #{VALID_SELECTS.map(&:to_s).join(', ')}")
              end
            end
          end

          # @return [Numeric]
          #   The limit is the duration of the longest test for which the sum of all the durations of the tests that are faster is more
          #   than `percent` percent of the total duration of the profiled tests
          private def compute_limit(times:, percent:)
            current = 0
            total = times.sum

            times.sort.take_while { |t| (current += t) / total < percent }.last
          end
        end

        attr_reader :time_provider, :limit, :filter

        def initialize(time_provider:, limit:, filter:)
          @time_provider = time_provider
          @limit = limit
          @filter = filter

          register_filter_module!
        end

        private def register_filter_module!
          ::Minitest::Test.send(:include, ::Ekylibre::Testing::Minitest::Profile::FilterModule)
        end
      end
    end
  end
end
