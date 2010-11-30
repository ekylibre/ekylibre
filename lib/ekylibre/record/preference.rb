# Class used to define Boolean
class ::Boolean
end

module Ekylibre::Record
  module Preference #:nodoc:
    
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def preference(name, type = String, options = {})
        code = ""

        code += "@@preferences ||= {}\n"
        code += "@@preferences['#{name}'] = {:default=>#{options[:default].inspect}, :type=>#{type.name}, :nature=>'#{::Preference::type_to_nature(type)}', :record_value_type=>'#{type.name}'}\n"

        preferences = (self.name == "Company" ? "self.preferences" : "self.company.preferences")
        unless self.methods.include? "preferences_reference"
          code += "def self.preferences_reference\n"
          code += "  @@preferences\n"
          code += "end\n"
        end

        unless self.instance_methods.include? "preferences_hash"
          code += "def preferences_hash\n"
          code += "  hash = {}\n"
          code += "  for k, v in @@preferences\n"
          code += "    hash[k] = self.preferred(k)\n"
          code += "  end\n"
          code += "  return hash\n"
          code += "end\n"
        end

        unless self.instance_methods.include? "preferences_list "
          code += "def preferences_list\n"
          code += "  hash = {}\n"
          code += "  for k, v in @@preferences\n"
          code += "    hash[k] = self.preference(k)\n"
          code += "  end\n"
          code += "  return hash\n"
          code += "end\n"
        end

        unless self.instance_methods.include? "prefer!"
          code += "def prefer!(name, value)\n"
          code += "  unless preference = #{preferences}.find_by_name(name)\n"
          code += "    attrs = {:name=>name}\n"
          code += "    attrs.merge!(:nature=>@@preferences[name][:nature], :record_value_type=>@@preferences[name][:record_value_type]) if @@preferences.has_key?(name.to_s)\n"
          code += "    preference = #{preferences}.build(attrs)\n"
          code += "  end\n"
          code += "  preference.value = value\n"
          code += "  preference.save\n"
          code += "end\n"
        end

        unless self.instance_methods.include? "preferred"
          code += "def preferred(name)\n"
          code += "  preference = #{preferences}.find_by_name(name)\n"
          code += "  if preference.nil? and @@preferences.has_key?(name.to_s)\n"
          code += "    preference = #{preferences}.new(:name=>name, :nature=>@@preferences[name][:nature], :record_value_type=>@@preferences[name][:record_value_type])\n"
          code += "    preference.value = @@preferences[name][:default] if @@preferences[name][:default]\n"
          code += "    preference.save!\n"
          code += "  elsif preference.nil?\n"
          code += "    raise ArgumentError.new('Undefined preference for #{self.name}: '+name.to_s)\n"
          code += "  end\n"
          code += "  return preference.value\n"
          code += "end\n"
        end

        code += "def "+(type == Boolean ? "prefer_#{name}?" : "preferred_#{name}")+"\n"
        code += "  return self.preferred('#{name}')\n"
#         code += "  preference = #{preferences}.find_by_name('#{name}')\n"
#         code += "  if preference.nil?\n"
#         code += "    preference = #{preferences}.new(:name=>'#{name}', :nature=>'#{::Preference::type_to_nature(type)}', :record_value_type=>'#{type.name}')\n"
#         code += "    preference.value = #{options[:default].inspect}\n" if options[:default]
#         code += "    preference.save!\n"
#         code += "  end\n"
#         code += "  return preference.value\n"
        code += "end\n"

        code += "def prefer_#{name}!(value)\n"
        code += "  self.prefer!('#{name}', value)\n"
        code += "end\n"

        # puts code
        class_eval code
      end

    end

  end
end
Ekylibre::Record::Base.class_eval { include Ekylibre::Record::Preference }
