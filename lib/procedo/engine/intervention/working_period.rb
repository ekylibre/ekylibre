module Procedo
  module Engine
    class Intervention
      class WorkingPeriod
        include Reassignable

        DEFAULT_DURATION = 2.hours

        attr_accessor :started_at, :stopped_at, :id

        def initialize(id, attributes = {})
          @id = id.to_s
          @started_at = begin
                          Time.parse(*attributes[:started_at])
                        rescue
                          nil
                        end
          @started_at ||= (Time.zone.now - DEFAULT_DURATION)
          @stopped_at = begin
                          Time.parse(*attributes[:stopped_at])
                        rescue
                          nil
                        end
          @stopped_at ||= (@started_at + DEFAULT_DURATION)
        end

        def duration
          @stopped_at - @started_at
        end

        def to_hash
          { started_at: @started_at.strftime('%Y-%m-%d %H:%M'), stopped_at: @stopped_at.strftime('%Y-%m-%d %H:%M') }
        end
        alias to_attributes to_hash

        def impact_with(steps)
          if steps.size != 1
            raise ArgumentError, 'Invalid steps: got ' + steps.inspect
          end
          reassign steps.first
        end
      end
    end
  end
end
