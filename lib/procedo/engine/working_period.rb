module Procedo
  module Engine
    class WorkingPeriod
      DEFAULT_DURATION = 2.hours

      attr_reader :started_at, :stopped_at, :id

      def initialize(id, attributes = {})
        @id = id
        @started_at = Time.new(*attributes[:started_at].split(/\D+/)) if attributes[:started_at]
        @started_at ||= (Time.zone.now - DEFAULT_DURATION)
        @stopped_at = Time.new(*attributes[:stopped_at].split(/\D+/)) if attributes[:stopped_at]
        @stopped_at ||= (@started_at + DEFAULT_DURATION)
      end

      def duration
        @stopped_at - @started_at
      end

      def to_hash
        { started_at: @started_at.strftime('%Y-%m-%d %H:%M'), stopped_at: @stopped_at.strftime('%Y-%m-%d %H:%M') }
      end
    end
  end
end
