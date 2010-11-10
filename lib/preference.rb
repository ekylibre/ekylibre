# Class used to define Boolean
class ::Boolean
end

module ActiveRecord
  module Preference #:nodoc:
    def self.actions
      [:create, :update, :destroy]
    end
    
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def preference(name, type, options = {})
        code = ""

        if type == Boolean
          code += "def prefer_#{name}?\n"
        else
          code += "def preferred_#{name}\n"
        end
        preferences = (self.name == "Company" ? "self.preferences" : "self.company.preferences")
        code += "  preference = #{preferences}.find_by_name('#{name}')\n"
        code += "  if preference.nil?\n"
        code += "    preference = #{preferences}.new(:name=>'#{name}')\n"
        code += "    preference.value = #{options[:default].inspect}\n" if options[:default]
        code += "    preference.save!\n"
        code += "  end\n"
        code += "  return preference.value\n"
        code += "end\n"

        code += "def prefer_#{name}!(value)\n"
        code += "  preference = #{preferences}.find_by_name('#{name}')\n"
        code += "  preference = #{preferences}.build(:name=>'#{name}') if preference.nil?\n"
        code += "  preference.value = value\n"
        code += "  preference.save\n"
        code += "end\n"

        class_eval code
      end

    end

  end
end
ActiveRecord::Base.class_eval { include ActiveRecord::Preference }
