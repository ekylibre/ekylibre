module Interventions
  module Phytosanitary
    module Models
      class Period
        class << self
          # @param [String|DateTime] start_date
          # @param [String|DateTime|nil] end_date
          def parse(start_date, end_date)
            new(
              parse_if_string(start_date),
              end_date.present? ? parse_if_string(end_date) : nil
            )
          end

          private

            # @param [String|DateTime] date
            # @return [DateTime]
            def parse_if_string(date)
              if date.is_a?(String)
                DateTime.soft_parse(date)
              else
                date
              end
            end
        end

        attr_reader :start_date, :end_date

        # @param [DateTime] start_date
        # @param [DateTime|nil] end_date
        def initialize(start_date, end_date)
          @start_date = start_date
          @end_date = end_date || start_date
        end

        # @param [Period] period
        # @return [Boolean]
        def intersect?(period)
          start_date <= period.start_date && period.start_date <= end_date ||
            start_date <= period.end_date && period.end_date <= end_date ||
            period.start_date <= start_date && end_date <= period.end_date
        end

        def duration
          (@end_date - @start_date).to_i.seconds
        end

      end
    end
  end
end
