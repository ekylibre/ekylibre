MODELS_DIR   = Rails.root.join("app", "models")
FIXTURES_DIR = Rails.root.join("test", "fixtures")
MODEL_TESTS_DIR = Rails.root.join("test", "models")

module AnnotateModels

  PREFIX = "= Informations"

  # Simple quoting for the default column value
  def self.quote(value)
    case value
      when NilClass                 then "NULL"
      when TrueClass                then "TRUE"
      when FalseClass               then "FALSE"
      when Float, Fixnum, Bignum    then value.to_s
      # BigDecimals need to be output in a non-normalized form and quoted.
      when BigDecimal               then value.to_s('F')
      else
        value.inspect
    end
  end


  def self.validable_column?(column)
    return ![:created_at, :creator_id, :creator, :updated_at, :updater_id, :updater, :position, :lock_version].include?(column.name.to_sym)
  end



  # Use the column information in an ActiveRecord class
  # to create a comment block containing a line for
  # each column. The line contains the column name,
  # the type (and length), and any optional attributes
  def self.get_schema_info(klass, header)
    # info = "# #{PREFIX}\n"
    info = header.gsub(/^/, '# ') # "# #{header}\n#\n"
    info << "# == Table: #{klass.table_name}\n#\n"
    #    info << "# Table name: #{klass.table_name}\n#\n"

    max_size = klass.column_names.collect{|name| name.size}.max + 1
    klass.columns.sort{|a,b| a.name<=>b.name}.each do |col|
      next if col.name.to_s =~ /\A\_/ # Custom fields
      attrs = []
      if col.default
        if col.default.is_a? Date
          attrs << "default(CURRENT_DATE)"
        else
          attrs << "default(#{quote(col.default)})"
        end
      end
      attrs << "not null" unless col.null
      attrs << "primary key" if col.name == klass.primary_key

      col_type = col.type.to_s
      if col_type == "decimal"
        col_type << "(#{col.precision}, #{col.scale})"
      else
        col_type << "(#{col.limit})" if col.limit
      end
      info << sprintf("#  %-#{max_size}.#{max_size}s:%-16.16s %s\n", col.name, col_type, attrs.join(", "))
    end

    # info << "#coding: utf-8 \n"
    info << "#\n"
  end



  # Use the column information in an ActiveRecord class
  # to create a comment block containing a line for
  # each column. The line contains the column name,
  # the type (and length), and any optional attributes
  def self.default_fixture(klass)
    info  = "#\n# == Fixture: #{klass.table_name}\n#\n"
    info += "# #{klass.table_name}_001:\n"
    klass.columns.sort{|a,b| a.name <=> b.name}.each do |col|
      next if [:created_at, :updated_at, :id, :lock_version].include? col.name.to_sym
      next if col.name =~ /\A\_/ # Custom fields
      next if col.name =~ /\_type$/ and klass.columns_hash[col.name.gsub(/\_type$/, "_id")]
      if !col.null or [:creator_id, :updater_id].include?(col.name.to_sym)
        if col.name.match(/_id$/)
          name = col.name.gsub(/_id$/, '')
          model = {"creator" => "user", "updater" => "user"}[name] || name
          info << "#   #{name}: #{model.pluralize}_001"
          info << " (Model)" if klass.columns_hash["#{name}_type"]
        else
          info << "#   #{col.name}: "
          if col.name.match(/_at$/)
            info << "#{Date.today.year - 1}-#{Date.today.year.modulo(12).to_s.rjust(2, '0')}-#{Date.today.year.modulo(28).to_s.rjust(2, '0')} #{(Date.today.year.modulo(12) + 8).to_s.rjust(2, '0')}:#{Date.today.year.modulo(60).to_s.rjust(2, '0')}:#{Date.today.year.modulo(30).to_s.rjust(2, '0')} +02:00"
          elsif col.name.match(/_on$/)
            info << "#{Date.today.year - 1}-#{Date.today.year.modulo(12).to_s.rjust(2, '0')}-#{Date.today.year.modulo(28).to_s.rjust(2, '0')}"
          elsif col.type == :boolean
            info << 'true'
          elsif col.type == :decimal or col.type == :integer
            info << "0"
          else
            info << '"Lorem ipsum"'
          end
        end
        info << "\n"
      end
    end
    info << "#\n"
    return info
  end


  # Add a schema block to a file. If the file already contains
  # a schema info block (a comment starting
  # with "Schema as of ..."), remove it first.

  def self.annotate_one_file(file_name, info_block)
    unless File.exist?(file_name)
      File.open(file_name, "w") { |f| f.puts "" }
    end
    if File.exist?(file_name)
      content = File.read(file_name)

      # Remove old schema info

      # old_prefix = "== Schema Information"
      # content.gsub!(/^#\n\n#/, '#')

      # content.sub!(/^# #{old_prefix}.*?\n(#.*\n)*\n/, '')
      # content.sub!(/# #{PREFIX}.*?\n(#.*\n)*\n+/, '')
      # content.sub!(/# #{PREFIX}.*?\n(#.*\n)*\n+/, '')
      content = "# #{PREFIX}\n"+content unless content.match(PREFIX)

      # Write it back
      # File.open(file_name, "w") { |f| f.puts info_block.gsub(/\n\n/, "\n#\n") +"\n"+ content }

      File.open(file_name, "w") { |f|
        f.puts content.sub(/# #{PREFIX}.*\n(#.*\n)*/, info_block).gsub!(/\ +\n/, "\n")
      }
    end
  end

  # Given the name of an ActiveRecord class, create a schema
  # info block (basically a comment containing information
  # on the columns and their types) and put it at the front
  # of the model and fixture source files.

  def self.annotate(klass, header)
    info = get_schema_info(klass, header)

    model_file_name = MODELS_DIR.join(klass.name.underscore + ".rb")
    annotate_one_file(model_file_name, info)

    fixture_file_name = FIXTURES_DIR.join(klass.table_name + ".yml")
    annotate_one_file(fixture_file_name, info+default_fixture(klass))

    unit_file_name = MODEL_TESTS_DIR.join(klass.name.underscore + "_test.rb")
    annotate_one_file(unit_file_name, info)
  end

  # Return a list of the model files to annotate. If we have
  # command line arguments, they're assumed to be either
  # the underscore or CamelCase versions of model names.
  # Otherwise we take all the model files in the
  # app/models directory.
  def self.get_model_names
    #models = ARGV.dup
    #models.shift
    models = []

    if models.empty?
      Dir.chdir(MODELS_DIR) do
        models = Dir["**/*.rb"].sort
      end
    end
    models
  end

  # We're passed a name of things that might be
  # ActiveRecord models. If we can find the class, and
  # if its a subclass of ActiveRecord::Base,
  # then pas it to the associated block

  def self.do_annotations
    Clean::Support.set_search_path!

    print " - Annotations: "

    header = PREFIX.dup

    header << "\n\n== License\n\n"
    header << "Ekylibre ERP - Simple agricultural ERP\nCopyright (C) 2008-2009 Brice Texier, Thibaud Merigon\nCopyright (C) 2010-2012 Brice Texier\nCopyright (C) 2012-#{Date.today.year} Brice Texier, David Joulin\n\nThis program is free software: you can redistribute it and/or modify\nit under the terms of the GNU Affero General Public License as published by\nthe Free Software Foundation, either version 3 of the License, or\nany later version.\n\nThis program is distributed in the hope that it will be useful,\nbut WITHOUT ANY WARRANTY; without even the implied warranty of\nMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\nGNU Affero General Public License for more details.\n\nYou should have received a copy of the GNU Affero General Public License\nalong with this program.  If not, see http://www.gnu.org/licenses.\n\n"

    version = ActiveRecord::Migrator.current_version rescue 0
#    if version > 0
#      header << "\n# Schema version: #{version}"
#    end

    errors = []
    self.get_model_names.each do |m|
      class_name = m.sub(/\.rb$/,'').camelize
      begin
        klass = class_name.split('::').inject(Object){ |klass,part| klass.const_get(part) }
        if klass < ActiveRecord::Base && !klass.abstract_class?
          # puts "Annotating #{class_name}"
          # print "."
          self.annotate(klass, header)
        else
          # print "S"
        end
      rescue Exception => e
        # print "F"
        errors << "Unable to annotate #{class_name}: #{e.message}\n"+e.backtrace.join("\n")
      end
    end
    print "#{errors.size.to_s.rjust(3)} errors\n"
    for error in errors
      puts error.gsub(/^/, "     ")
    end
  end


end

desc "Add schema information (as comments) to model files"
task :annotations => :environment do
  AnnotateModels.do_annotations
end
