module Userstamp
  module Stamper
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
    end

    module ClassMethods
      def model_stamper
        # don't allow multiple calls
        return if included_modules.include?(Userstamp::Stamper::InstanceMethods)
        send(:extend, Userstamp::Stamper::InstanceMethods)
      end
    end

    module InstanceMethods
      # Used to set the stamper for a particular request. See the Userstamp module for more
      # details on how to use this method.
      def stamper=(object)
        object_stamper = if object.is_a?(ActiveRecord::Base)
                           object.send("#{object.class.primary_key}".to_sym)
                         else
                           object
                         end

        Thread.current["#{to_s.downcase}_#{object_id}_stamper"] = object_stamper
      end

      # Retrieves the existing stamper for the current request.
      def stamper
        Thread.current["#{to_s.downcase}_#{object_id}_stamper"]
      end

      # Sets the stamper back to +nil+ to prepare for the next request.
      def reset_stamper
        Thread.current["#{to_s.downcase}_#{object_id}_stamper"] = nil
      end
    end
  end
end
