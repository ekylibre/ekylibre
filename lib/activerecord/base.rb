module ActiveRecord

  class Base

    # Updates the associated record with values matching those of the instance attributes.
    # Returns the number of affected rows.
    def update_3_0_0_beta4(attribute_names = @attributes.keys)
      attributes_with_values = arel_attributes_values(false, false, attribute_names)
      return 0 if attributes_with_values.empty?
      self.class.unscoped.where(self.class.arel_table[self.class.primary_key].eq(id)).arel.update(attributes_with_values)
    end


    # Creates a record with values matching those of the instance attributes
    # and returns its id.
    def create_3_0_0_beta4
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
end
