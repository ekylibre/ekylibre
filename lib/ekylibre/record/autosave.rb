module Ekylibre::Record
  module Autosave #:nodoc:
    
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods

      def autosave(*reflections_list)
        code, options = '', {:callbacks=>[:after_save, :after_destroy]}
        options.merge(reflections_list.delete_at(-1)) if reflections_list.last.is_a? Hash

        method_name = options[:method] || "autosave_"+reflections_list.join("_and_")
        for callback in options[:callbacks]
          code  += "#{callback} :#{method_name}\n"
        end

        code  += "def #{method_name}\n"
        for reflection in reflections_list
          ref = self.reflections[reflection]
          raise ArgumentError.new("reflection unknown (#{self.reflections.keys.to_sentence} available)") unless ref
          if ref.macro == :belongs_to or ref.macro == :has_one
            code += "  if self.#{reflection} and not (self.#{reflection}.destroyed? or self.#{reflection}.marked_for_destruction?)\n"
            code += "    unless self.#{reflection}.reload.save\n"
            code += "      errors.add_from_record(self.#{reflection})\n"
            code += "    end\n"
            code += "  end\n"
          else
            code += "  for item in self.#{reflection}\n"
            code += "    unless item.#{reflection}.destroyed? or item.#{reflection}.marked_for_destruction?\n"
            code += "      unless item.reload.save\n"
            code += "        errors.add_from_record(item)\n"
            code += "      end\n"
            code += "    end\n"
            code += "  end\n"
          end
        end
        code += "end\n"
        # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
        class_eval code
      end


    end
  end
end

Ekylibre::Record::Base.send(:include, Ekylibre::Record::Autosave)
