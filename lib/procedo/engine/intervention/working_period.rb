module Procedo
  module Engine
    class Intervention
      class WorkingPeriod
        DEFAULT_DURATION = 2.hours

        attr_accessor :started_at, :stopped_at, :id

        def initialize(id, attributes = {})
          @id = id.to_s
          @started_at = begin
                          Time.new(*attributes[:started_at].split(/\D+/))
                        rescue
                          nil
                        end
          @started_at ||= (Time.zone.now - DEFAULT_DURATION)
          @stopped_at = begin
                          Time.new(*attributes[:stopped_at].split(/\D+/))
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

        def impact_with(steps)
          raise 'Invalid steps: ' + steps.inspect if steps.size != 1
          field = steps.first
          send(field + '=', send(field))
        end
      end
    end
  end
end
