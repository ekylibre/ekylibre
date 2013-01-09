# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2010 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#


module Ekylibre::Record

  class Base < ActiveRecord::Base
    self.abstract_class = true

    # Replaces old module: ActiveRecord::Acts::Tree
    include ActsAsTree

    # Permits to use enumerize in all models
    extend Enumerize

    # Make all models stampables
    self.stampable

    def destroyable?
      true
    end

    def updateable?
      true
    end

    def others
      self.class.where("id != ?", self.id || -1)
    end

    # Defined a default relation to CustomField
    # has_many :custom_field_data, :as => :customized, :dependent => :delete_all, :inverse_of => :customized
    # attr_accessible :custom_field_data
    # accepts_nested_attributes_for :custom_field_data


    # Updates the associated record with values matching those of the instance attributes.
    # Returns the number of affected rows.
    def update_strictly(attribute_names = @attributes.keys)
      attributes_with_values = arel_attributes_values(false, false, attribute_names)
      return 0 if attributes_with_values.empty?
      klass = self.class
      stmt = klass.unscoped.where(klass.arel_table[klass.primary_key].eq(id)).arel.compile_update(attributes_with_values)
      klass.connection.update stmt
    end

    # Creates a record with values matching those of the instance attributes
    # and returns its id.
    def create_strictly
      attributes_values = arel_attributes_values(!id.nil?)

      new_id = self.class.unscoped.insert attributes_values

      self.id ||= new_id

      IdentityMap.add(self) if defined?(IdentityMap) and IdentityMap.enabled?
      @new_record = false
      id
    end


    @@readonly_counter = 0

    class << self

      attr_reader :scopes
      @scopes = []

      # Permits to consider something and something_id like the same
      def scope_with_registration(name, scope_options = {}, &block)
        @scopes ||= []
        @scopes << name
        scope_without_registration(name, scope_options, &block)
      end
      alias_method_chain :scope, :registration


      # Permits to consider something and something_id like the same
      def human_attribute_name_with_id(attribute, options = {})
        human_attribute_name_without_id(attribute.to_s.gsub(/_id$/, ''), options)
      end
      alias_method_chain :human_attribute_name, :id

      # Permits to add conditions on attr_readonly
      def attr_readonly_with_conditions(*args)
        options = args.extract_options!
        return attr_readonly_without_conditions(*args) unless options[:if]
        method_name = "readonly_#{@@readonly_counter+=1}?"
        self.send(:define_method, method_name, options[:if])
        code = ""
        code += "before_update do\n"
        code += "  if self.#{method_name}(#{'self' if options[:if].arity>0})\n"
        code += "    old = self.class.find(self.id)\n"
        for attribute in args
          code += "  self['#{attribute}'] = old['#{attribute}']\n"
        end
        code += "  end\n"
        code += "end\n"
        class_eval code
      end
      alias_method_chain :attr_readonly, :conditions

    end




  end

end
