module ConditionalReadonly
  extend ActiveSupport::Concern

  included do
    class << self
      prepend KlassMethods
    end
  end

  module KlassMethods
    def attr_readonly(*args)
      options = args.extract_options!
      return super(*args) unless options[:if]

      if options[:if].is_a?(Symbol)
        method_name = options[:if]
      else
        self.readonly_counter ||= 0
        method_name = "readonly_#{self.readonly_counter += 1}?"
        send(:define_method, method_name, options[:if])
      end

      before_update do
        if self.send(method_name)
          old = self.class.find(self.id)
          args.each do |attribute|
            self[attribute] = old[attribute]
          end
        end
      end
    end
  end
end
