module MigrationHelper

  module Indexes
    # Renames index using the standard convention
    def normalize_indexes(table)
      for index in indexes(table)
        expected_name = ("index_#{table}_on_" + index.columns.join("_and_")).to_sym
        if index.name.to_sym != expected_name
          rename_index table, index.name.to_sym, expected_name
        end
      end
    end


    # Prevents errors from SQLite only
    # Renames too long index names with short names
    # At the end of the operations the indexes are renamed back.
    def protect_indexes(tables, &block)
      if adapter_name == "SQLite"
        sqlite_indexes = []
        root, count = rand.to_s[2..-1].to_i.to_s(36), "a"
        Struct.new("ShortIndexName", :table, :name, :short_name)

        suppress_messages do
          for table in tables
            for index in indexes(table)
              if index.name.length > 32
                sqlite_indexes << Struct::ShortIndexName.new(index.table, index.name, "ndx#{root}_#{count}")
                count.succ!
              end
            end
          end
          for index in sqlite_indexes
            rename_index index.table, index.name, index.short_name
          end
        end

        # Do all the stuff with the given tables
        yield

        # Re-add annoying indexes for SQLite
        suppress_messages do
          for index in sqlite_indexes.reverse
            rename_index index.table, index.short_name, index.name
          end
        end
      else
        yield
      end
    end

  end

  module Reading

    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)
    end

    module InstanceMethods
      def reading(options = {})
        options[:null] = true unless options.has_key?(:null)
        self.string        :indicator_name,        null: options[:null]
        self.string        :indicator_datatype,    null: options[:null]
        self.decimal       :absolute_measure_value_value,   precision: 19, scale: 4
        self.string        :absolute_measure_value_unit
        self.boolean       :boolean_value,         default: false, null: false
        self.string        :choice_value
        self.decimal       :decimal_value,         precision: 19, scale: 4
        self.geometry      :geometry_value,        srid: 4326
        self.integer       :integer_value
        self.decimal       :measure_value_value,   precision: 19, scale: 4
        self.string        :measure_value_unit
        # self.multi_polygon :multi_polygon_value,   srid: 4326
        if options[:native_point]
          self.point       :point_value,           srid: 4326
        else
          self.st_point    :point_value,           srid: 4326
        end
        self.text          :string_value
        if options[:index]
          options[:index] = {} unless options[:index].is_a?(Hash)
          self.index(:indicator_name, options[:index])
        end
      end
    end

  end
end

ActiveRecord::Migration.send(:include, MigrationHelper::Indexes)
ActiveRecord::ConnectionAdapters::TableDefinition.send(:include, MigrationHelper::Reading)
