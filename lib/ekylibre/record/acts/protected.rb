module Ekylibre
  module Record
    class RecordNotUpdateable < ActiveRecord::RecordNotSaved
    end

    class RecordNotDestroyable < ActiveRecord::RecordNotSaved
    end

    class RecordNotCreateable < ActiveRecord::RecordNotSaved
    end

    module Acts #:nodoc:
      module Protected #:nodoc:
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          # Blocks update or destroy if necessary
          def protect(options = {}, &block)
            options[:on] = %i[update destroy] unless options[:on]
            code = ''.c
            for callback in [options[:on]].flatten
              method_name = "protected_on_#{callback}?".to_sym

              code << "before_#{callback} :raise_exception_unless_#{callback}able?\n"

              code << "def raise_exception_unless_#{callback}able?\n"
              code << "  unless self.#{callback}able?\n"
              if options[:"allow_#{callback}_on"]
                code << '  if self.changed.any? { |e| !' + options[:"allow_#{callback}_on"].to_s + ".include? e }\n"
              end
              code << "      raise RecordNot#{callback.to_s.camelcase}able.new('Record cannot be #{callback}d', self)\n"
              code << "  end\n" if options[:"allow_#{callback}_on"]
              code << "  end\n"
              code << "end\n"

              code << "def #{callback}able?\n"
              code << "  !#{method_name}\n"
              code << "end\n"

              define_method(method_name, &block) if block_given?
            end
            class_eval code
          end

          # Blocks update or destroy if necessary
          # If result is false, it stops intervention
          def secure(options = {}, &block)
            options[:on] = %i[update destroy] unless options[:on]
            code = ''.c
            for callback in [options[:on]].flatten
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
Ekylibre::Record::Base.send(:include, Ekylibre::Record::Acts::Protected)
