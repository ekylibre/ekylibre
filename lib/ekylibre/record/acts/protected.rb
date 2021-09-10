module Ekylibre
  module Record
    module Acts
      module Protected
        def self.included(base)
          base.extend(ClassMethods)
        end

        def createable?
          true
        end

        def updateable?
          true
        end

        def destroyable?
          true
        end

        def form_reachable?
          true
        end

        module ClassMethods
          # Blocks update or destroy if necessary
          def protect(options = {}, &block)
            options[:on] = %i[update destroy] unless options[:on]
            code = ''.c
            [options[:on]].flatten.each do |callback|
              method_name = "protected_on_#{callback}?".to_sym

              send("before_#{callback}", "raise_exception_unless_#{callback}able?")

              define_method "raise_exception_unless_#{callback}able?" do
                allowed_fields = options[:"allow_#{callback}_on"] || []
                bypass = changed.all? { |change| allowed_fields.map(&:to_s).include?(change) }

                unless send("#{callback}able?") || bypass
                  raise "Ekylibre::Record::RecordNot#{callback.to_s.camelcase}able".constantize.new("Record cannot be #{callback}d", self)
                end
              end

              define_method "#{callback}able?" do
                !send(method_name)
              end

              define_method(method_name, &block) if block_given?
            end

            define_method 'form_reachable?' do
              updateable? || !!options[:form_reachable]
            end

            # Blocks update or destroy if necessary
            # If result is false, it stops intervention
            def secure(options = {}, &block)
              options[:on] = %i[update destroy] unless options[:on]
              code = ''.c
              [options[:on]].flatten.each do |callback|
                method_name = "secured_on_#{callback}?".to_sym

                code << "before_#{callback} :secure_#{callback}ability!\n"

                code << "def secure_#{callback}ability!\n"
                code << "  unless self.#{callback}able?\n"
                code << "    raise RecordNot#{callback.to_s.camelcase}able.new('Record cannot be #{callback}d because it is secured', self)\n"
                code << "  end\n"
                code << "end\n"

                code << "def #{callback}able?\n"
                code << "  #{method_name}\n"
                code << "end\n"

                define_method(method_name, &block) if block_given?
              end
              class_eval code
            end
          end
        end
      end
    end
  end
end
