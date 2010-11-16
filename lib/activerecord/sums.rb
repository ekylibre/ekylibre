module ActiveRecord
  module Sums #:nodoc:
    
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods


      # Sums columns and puts result in "Parent" table without validations or callbacks.
      def sums(target, children, *args)
        options={}
        for arg in args
          if arg.is_a? Symbol or arg.is_a? String
            options[arg.to_sym] = arg.to_sym
          elsif arg.is_a? Hash
            options.merge!(arg)
          else
            raise ArgumentError.new("Unvalid type #{arg.inspect}:#{arg.class.name}")
          end
        end          
        method_name = options.delete(:method) || "sums_#{children}_in_#{target}"
        code = ""
        for callback in (callbacks = options.delete(:callbacks) || [:after_save, :after_destroy])
          code  += "#{callback} :#{method_name}\n"
        end
        code += "def #{method_name}\n"
        code += "  "+options.collect{|k, v| v}.join(" = ")+" = 0\n"
        code += "  for #{children.to_s.singularize} in self.#{target}.#{children}\n"
        for k, v in options
          code += "    #{v} += "+(k.is_a?(Symbol) ? "#{children.to_s.singularize}.#{k}" : k)+"\n"
        end
        code += "  end\n"
        code += "  "+Ekylibre.references[self.name.underscore.to_sym]["#{target}_id".to_sym].to_s.classify+".update_all({"+options.collect{|k, v| ":#{v}=>#{v}"}.join(", ")+"}, {:company_id=>self.company_id, :id=>self.#{target}_id})\n"
        code += "  return true\n"
        code += "end\n"
        # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
        class_eval code
      end

      
    end
  end
end

ActiveRecord::Base.send(:include, ActiveRecord::Sums)
