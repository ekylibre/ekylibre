module Clean
  # Annotations tool permits to set model description in code
  # of models, fixtures and model tests
  module Annotations
    MODELS_DIR = Rails.root.join('app', 'models')
    FIXTURES_DIR = Rails.root.join('test', 'fixtures')
    MODEL_TESTS_DIR = Rails.root.join('test', 'models')
    PREFIX = '= Informations'.freeze

    class << self
      # Simple quoting for the default column value
      def quote_value(value, type = :string)
        case type
        when :boolean then
          (value == 'true' ? 'TRUE' : 'FALSE')
        when :decimal, :float, :integer then
          value.to_s
        else
          value.inspect
        end
      end

      # Simple quoting for the default column value
      def quote(value)
        case value
        when NilClass then
          'NULL'
        when TrueClass then
          'TRUE'
        when FalseClass then
          'FALSE'
        when Float, Integer, Integer then
          value.to_s
          # BigDecimals need to be output in a non-normalized form and quoted.
        when BigDecimal then
          value.to_s('F')
        else
          value.inspect
        end
      end

      def validable_column?(column)
        !%i[created_at creator_id creator updated_at updater_id updater position lock_version].include?(column.name.to_sym)
      end

      # Use the column information in an ActiveRecord class
      # to create a comment block containing a line for
      # each column. The line contains the column name,
      # the type (and length), and any optional attributes
      def get_schema_info(klass, header)
        # info = "# #{PREFIX}\n"
        info = header.gsub(/^/, '# ') # "# #{header}\n#\n"
        info << "# == Table: #{klass.table_name}\n#\n"
        #    info << "# Table name: #{klass.table_name}\n#\n"

        max_size = klass.column_names.collect(&:size).max
        klass.columns.sort_by(&:name).each do |col|
          next if col.name.to_s.start_with?('_') # Custom fields
          attrs = []
          if col.default
            attrs << 'default(' + (col.default.is_a?(Date) ? 'CURRENT_DATE' : quote_value(col.default, col.type)) + ')'
          end
          attrs << 'not null' unless col.null
          attrs << 'primary key' if col.name == klass.primary_key

          col_type = col.type.to_s

          if col_type == 'decimal'
            col_type << "(#{col.precision}, #{col.scale})"
          elsif col_type == 'string' && col.sql_type == 'interval'
            col_type = 'interval'
          elsif col.limit
            col_type << "(#{col.limit.inspect})"
          end

          # Name type with rails symbols
          col_type = ":#{col_type}"

          # Wrap in an array if defined this way
          col_type = "Array<#{col_type}>" if col.array

          # info << sprintf("#  %-#{max_size}.#{max_size}s:%-16.16s %s\n", col.name, col_type, attrs.join(", "))
          info << "#  #{col.name.to_s.ljust(max_size)} #{col_type.to_s.ljust(17)} #{attrs.join(', ')}\n"
        end

        # info << "#coding: utf-8 \n"
        info << "#\n"
      end

      # Add a schema block to a file. If the file already contains
      # a schema info block (a comment starting
      # with "Schema as of ..."), remove it first.
      def annotate_one_file(file_name, info_block)
        if File.exist?(file_name)
          content = File.read(file_name)

          content = "# #{PREFIX}\n" + content unless content.match(PREFIX)

          File.open(file_name, 'w') do |f|
            f.puts content.sub(/# #{PREFIX}.*\n(#.*\n)*/, info_block).gsub!(/\ +\n/, "\n")
          end
        end
      end

      # Given the name of an ActiveRecord class, create a schema
      # info block (basically a comment containing information
      # on the columns and their types) and put it at the front
      # of the model and fixture source files.
      def annotate(klass, header, types = [])
        info = get_schema_info(klass, header)

        if types.include?(:models)
          model_file_name = MODELS_DIR.join(klass.name.underscore + '.rb')
          annotate_one_file(model_file_name, info)
        end

        if types.include?(:fixtures)
          fixture_file_name = FIXTURES_DIR.join(klass.table_name + '.yml')
          annotate_one_file(fixture_file_name, info)
        end

        if types.include?(:model_tests)
          unit_file_name = MODEL_TESTS_DIR.join(klass.name.underscore + '_test.rb')
          annotate_one_file(unit_file_name, info)
        end
      end

      # Return a list of the model files to annotate. If we have
      # command line arguments, they're assumed to be either
      # the underscore or CamelCase versions of model names.
      # Otherwise we take all the model files in the
      # app/models directory.
      def model_names
        models = []
        if models.empty?
          Dir.chdir(MODELS_DIR) do
            models = Dir['**/*.rb'].sort
            models.delete_if { |m| m =~ /\Aconcerns\// }
          end
        end
        models
      end

      # We're passed a name of things that might be
      # ActiveRecord models. If we can find the class, and
      # if its a subclass of ActiveRecord::Base,
      # then pas it to the associated block
      def run(options = {})
        if verbose = !options[:verbose].is_a?(FalseClass)
          print ' - Annotations: '
        end

        Clean::Support.set_search_path!

        types = %i[models fixtures model_tests]
        types &= [options.delete(:only)].flatten if options[:only]
        types -= [options.delete(:except)].flatten if options[:except]

        header = PREFIX.dup

        header << "\n\n== License\n\n"
        header << "Ekylibre - Simple agricultural ERP\nCopyright (C) 2008-2009 Brice Texier, Thibaud Merigon\nCopyright (C) 2010-2012 Brice Texier\nCopyright (C) 2012-2014 Brice Texier, David Joulin\nCopyright (C) 2015-#{Time.zone.today.year} Ekylibre SAS\n\nThis program is free software: you can redistribute it and/or modify\nit under the terms of the GNU Affero General Public License as published by\nthe Free Software Foundation, either version 3 of the License, or\nany later version.\n\nThis program is distributed in the hope that it will be useful,\nbut WITHOUT ANY WARRANTY; without even the implied warranty of\nMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\nGNU Affero General Public License for more details.\n\nYou should have received a copy of the GNU Affero General Public License\nalong with this program.  If not, see http://www.gnu.org/licenses.\n\n"

        version = begin
                    ActiveRecord::Migrator.current_version
                  rescue
                    0
                  end

        errors = []

        model_names.each do |m|
          class_name = m.sub(/\.rb$/, '').camelize
          begin
            klass = class_name.split('::').inject(Object) { |klass, part| klass.const_get(part) }
            if klass < ActiveRecord::Base && !klass.abstract_class?
              annotate(klass, header, types)
            end
          rescue LoadError => le
            errors << "Unable to annotate #{class_name}: #{le.message}\n"
          rescue StandardError => e
            errors << "Unable to annotate #{class_name}: #{e.message}\n" + e.backtrace.join("\n")
          end
        end

        if verbose
          print "#{errors.size.to_s.rjust(3)} errors\n"
          for error in errors
            puts error.gsub(/^/, '     ')
          end
        end
      end
    end
  end
end
