module ActiveRecord
  module Acts #:nodoc:
    module Protected #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        def protect_on_update(&block)
          define_method :updateable?, &block
          class_eval "before_update {|record| record.updateable? }"
#           if Rails.version.match(/^2\.3/)
#             class_eval "before_update {|record| return false unless record.updateable? }"
#           else
#             class_eval "before_update { return false unless self.updateable? }"
#           end
        end



        def protect_on_destroy(&block)
          define_method :destroyable?, &block
          class_eval "before_destroy { |record| record.destroyable? }"
        end


      end 
    end
  end
end
