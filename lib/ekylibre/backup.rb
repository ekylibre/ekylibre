# -*- coding: utf-8 -*-
module Ekylibre
  module Backup

    def self.create(options = {})
      creator, with_files = options[:creator], options[:with_prints]
      version = (ActiveRecord::Migrator.current_version rescue 0)
      file = self.temporary_dir.join("backup-#{Time.now.strftime('%Y%m%d-%H%M%S')}.zip")
      doc = Nokogiri::XML::Document.new
      doc.root = backup = Nokogiri::XML::Node.new('backup', doc)

      # doc = LibXML::XML::Document.new
      # doc.root = backup = LibXML::XML::Node.new('backup')

      {'version' => version, 'creation-date' => Date.today, 'creator' => creator}.each{ |k,v| backup[k]=v.to_s }
      backup << root = Nokogiri::XML::Node.new('company', doc)
      root[:name] = Entity.of_company.full_name
      n = 0
      start = Time.now.to_i
      for model in Ekylibre.models.select{|m| m.to_s.pluralize.classify.constantize.superclass == Ekylibre::Record::Base }
        klass = model.to_s.pluralize.classify.constantize.unscoped
        rows_count = klass.count
        n += rows_count
        root << rows = Nokogiri::XML::Node.new('rows', doc)
        {'model' => model.to_s, 'records-count' => rows_count.to_s}.each{|k,v| rows[k] = v}
        klass.find_each do |item|
          rows << row = Nokogiri::XML::Node.new('row', doc)
          item.attributes.each{|k,v| row[k] = v.to_s}
        end
      end
      # backup.add_attributes('records-count'=>n.to_s, 'generation-duration'=>(Time.now.to_i-start).to_s)
      stream = doc.to_s

      Zip::ZipFile.open(file, Zip::ZipFile::CREATE) do |zile|
        zile.get_output_stream("backup.xml") { |f| f.puts(stream) }
        files_dir = Document.private_directory
        if with_files and File.exist?(files_dir)
          Dir.chdir(files_dir) do
            for document in Dir.glob(File.join("**", "*"))
              zile.add("Files/#{document}", File.join(files_dir, document))
            end
          end
        end
      end
      return file
    end




    # Restore backup with archived documents if requested
    # This system requires a database with no foreign key constraints
    # Steps of restoring
    #   - Removes all existing data
    #   - Add all backup records with bad IDs
    #   - Update all records with new ID using a big hash containing all the new IDs
    #   - Put in place the archived documents if present in backup
    def self.restore(file, options={})
      raise ArgumentError.new("Expecting String, #{file.class.name} instead") unless file.is_a? String or file.is_a? Pathname
      verbose = options[:verbose]
      files_dir = Document.private_directory
      # Uncompressing
      puts "R> Uncompressing archive..." if verbose
      archive = self.temporary_dir.join("uncompressed-backup-#{Time.now.strftime('%Y%m%d-%H%M%S')}")
      stream = nil

      # Extract all files in archive
      Zip::ZipFile.open(file) do |zile|
        zile.each do |entry|
          FileUtils.mkdir_p(File.join(archive, entry.name.split(/[\\\/]+/)[0..-2]))
          zile.extract(entry, File.join(archive, entry.name))
        end
      end

      # Parsing
      version = (ActiveRecord::Migrator.current_version rescue 0)
      puts "R> Parsing backup.xml (#{version})..."  if verbose
      f = File.open(File.join(archive, "backup.xml"))
      doc = Nokogiri::XML(f)do |config|
        config.strict.nonet.noblanks.noent
      end
      f.close
      backup = doc.root
      attr_version = backup['version']
      return false if not attr_version or (attr_version != version.to_s)

      root = backup.children.first
      ActiveRecord::Base.transaction do
        # Delete all existing data
        puts "R> Removing existing data..."  if verbose
        for model in Ekylibre.models
          model.to_s.pluralize.classify.constantize.delete_all
        end

        # Load all data
        puts "R> Loading backup data..."  if verbose
        code  = ""

        all_rows = {}
        root.element_children.each_with_index do |rows, index|
          model_name = rows.attr('model').to_sym
          all_rows[model_name] = rows
          model = model_name.to_s.pluralize.classify.constantize
          columns = model.columns_hash.keys.map(&:to_sym)
          if model.methods.include?(:acts_as_nested_set_options)
            columns.delete(model.acts_as_nested_set_options[:left_column].to_sym)
            columns.delete(model.acts_as_nested_set_options[:right_column].to_sym)
            columns.delete(model.acts_as_nested_set_options[:depth_column].to_sym)
          end
          code << "all_rows[:#{model_name}].element_children.each do |row|\n"
          code << "  #{model.name}.new({" + columns.collect{|a| ":#{a} => row.attr('#{a}')"}.join(", ") + "}, :validate => false, :without_protection => true).sneaky_save\n"
          code << "end\n"
          code << "#{model.name}.rebuild!\n" if model.methods.include?(:acts_as_nested_set_options)
        end
        # code.split("\n").each_with_index{|l, x| puts((x+1).to_s.rjust(4)+": "+l)}
        eval(code)

        # Place files
        backup_files = File.join(archive, "Files")
        if File.exist?(backup_files)
          puts "R> Replacing files..." if verbose
          tmp_dir = files_dir.join("..", ".old-files")
          FileUtils.mv(files_dir, tmp_dir)
          FileUtils.mv(backup_files, files_dir)
          FileUtils.rm_rf(tmp_dir)
        end
      end

      # Clean temporary directory by removing backup data
      FileUtils.rm_rf(archive)
      return true
    end



    protected

    def self.temporary_dir
      dir = Rails.root.join("tmp", "backups")
      FileUtils.mkdir_p(dir)
      return dir
    end

  end
end
