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

    # Make all models stampables
    self.stampable


    if Rails.version.match(/^2\.3/)

      def update_strictly(attribute_names = @attributes.keys)
        self.send(:update_without_callbacks) # , attribute_names
      end

      def create_strictly
        self.send(:create_without_callbacks)
      end

    else
      # Updates the associated record with values matching those of the instance attributes.
      # Returns the number of affected rows.
      def update_strictly(attribute_names = @attributes.keys)
        attributes_with_values = arel_attributes_values(false, false, attribute_names)
        return 0 if attributes_with_values.empty?
        self.class.unscoped.where(self.class.arel_table[self.class.primary_key].eq(id)).arel.update(attributes_with_values)
      end


      # Creates a record with values matching those of the instance attributes
      # and returns its id.
      def create_strictly
        if self.id.nil? && connection.prefetch_primary_key?(self.class.table_name)
          self.id = connection.next_sequence_value(self.class.sequence_name)
        end

        attributes_values = arel_attributes_values

        new_id = if attributes_values.empty?
                   self.class.unscoped.insert connection.empty_insert_statement_value
                 else
                   self.class.unscoped.insert attributes_values
                 end

        self.id ||= new_id

        @new_record = false
        id
      end
    end


    @@readonly_counter = 0

    class << self

      def attr_readonly_with_conditions(*args)
        options = args.extract_options!
        return attr_readonly_without_conditions(args) unless options[:if]
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
