module Ekylibre
  module Record
    module Sums #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Sums columns and puts result in "Parent" table without validations or callbacks.
        def sums(target, children, *args)
          options = args.extract_options!
          args.each do |arg|
            if arg.is_a?(Symbol) || arg.is_a?(String)
              options[arg.to_sym] = arg.to_sym
            elsif arg.is_a? Hash
              options.merge!(arg)
            else
              raise ArgumentError, "Unvalid type #{arg.inspect}:#{arg.class.name}"
            end
          end
          method_name = options.delete(:method) || "sums_#{children}_of_#{target}"
          target_reflection = reflect_on_association(target)
          target_id = target_reflection.foreign_key.to_sym
          record = children.to_s.singularize
          code = ''

          callbacks = options.delete(:callbacks) || %i[after_save after_destroy]
          for callback in callbacks
            code << "#{callback} :#{method_name}\n"
          end

          from = options.delete(:from)
          negate = options.delete(:negate)

          code << "def #{method_name}\n"
          code << "  return unless self.#{target}\n"
          code << '  ' + options.values.join(' = ') + " = 0\n"
          code << "  self.#{target}.reload\n"
          # code << "  #{self.name}.where(#{target_id}: self.#{target_id}).find_each do |#{record}|\n"
          # code << "  #{self.name}.where(#{target_id}: self.#{target_id}).find_each do |#{record}|\n"
          code << "  #{target}.#{children}.find_each do |#{record}|\n"
          options.each do |k, v|
            code << '    x = ' + (k.is_a?(Symbol) ? "#{record}.#{k}" : k) + "#{from ? '.to_s.to_f' : ''}\n"
            code << "    if x.nil?\n"
            code << "      Rails.logger.warn 'Nil value in sums'\n"
            code << "      x = 0.0\n"
            code << "    end\n"
            code += if negate
                      "    #{v} -= x\n"
                    else
                      "    #{v} += x\n"
                    end
          end
          code << "  end\n"
          # code << "  " + Ekylibre::Schema.references(self.name.underscore.to_sym, target_id).to_s.camelcase + ".where(id: self.#{target_id}).update_all(" + options.collect{|k, v| "#{v}: #{v}"}.join(", ") + ")\n"
          # code << "  " + target_reflection.class_name + ".where(id: self.#{target_id}).update_all(" + options.collect{|k, v| "#{v}: #{v}"}.join(", ") + ")\n"
          code << "  #{target}.update_columns(" + options.values.collect { |v| "#{v}: #{v}" }.join(', ') + ")\n"
          code << "end\n"

          # code.split("\n").each_with_index{|l, x| puts((x+1).to_s.rjust(4)+": "+l)}

          class_eval code
        end
      end
    end
  end
end

Ekylibre::Record::Base.send(:include, Ekylibre::Record::Sums)
