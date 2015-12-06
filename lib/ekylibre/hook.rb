module Ekylibre
  class Hook
    @subscriptions = {}.with_indifferent_access

    class << self
      # Publish a given event/message
      def publish(message, data = {})
        Rails.logger.info("Publish: #{message.to_s.yellow}")
        if @subscriptions[message] && @subscriptions[message].any?
          @subscriptions[message].each_with_index do |block, index|
            Rails.logger.info "Push to #{message}##{index}".yellow
            if block.arity >= 1
              block.call(data)
            else
              block.call
            end
            Rails.logger.info "Push to #{message}##{index}: terminated".yellow
          end
        end
      end

      # Subscribe to a given event/message
      def subscribe(message, proc = nil, &block)
        @subscriptions[message] ||= []
        if proc.respond_to?(:call)
          @subscriptions[message] << proc
        elsif block_given?
          @subscriptions[message] << block
        else
          fail 'Need block or proc'
        end
      end
    end
  end
end
