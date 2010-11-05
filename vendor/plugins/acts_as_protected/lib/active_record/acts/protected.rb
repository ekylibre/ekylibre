module ActiveRecord
  module Acts #:nodoc:
    module Protected #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        def protect_on_update(&block)
          define_method :updateable?, &block
          class_eval "before_update do |record|\nreturn false unless self.updateable?\nend"
        end



        def protect_on_destroy(&block)
          define_method :destroyable?, &block
          class_eval "before_destroy do |record|\nreturn false unless self.destroyable?\nend"
        end


      end 
    end
  end
end
