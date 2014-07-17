module Clean
  module Validations
    class << self

      def validable_column?(column)
        return false if [:created_at, :creator_id, :creator, :updated_at, :updater_id, :updater, :position, :lock_version].include?(column.name.to_sym)
        return false if column.name.to_s.match(/^\_/)
        return true
      end


      def search_missing_validations(model)
        code = ""

        return code unless model.superclass == Ekylibre::Record::Base

        columns = model.content_columns.delete_if{|c| !validable_column?(c)}.sort{|a,b| a.name.to_s <=> b.name.to_s}

        cs = columns.select{|c| c.type == :integer}
        code << "  validates_numericality_of "+cs.collect{|c| ":#{c.name}"}.join(', ')+", allow_nil: true, only_integer: true\n" if cs.size > 0

        cs = columns.select{|c| c.number? and c.type != :integer}
        code << "  validates_numericality_of "+cs.collect{|c| ":#{c.name}"}.join(', ')+", allow_nil: true\n" if cs.size > 0

        limits = columns.select{|c| c.text? and c.limit}.collect{|c| c.limit}.uniq.sort
        for limit in limits
          cs = columns.select{|c| c.text? and c.limit == limit}
          code << "  validates_length_of "+cs.collect{|c| ":#{c.name}"}.join(', ')+", allow_nil: true, maximum: #{limit}\n"
        end

        cs = columns.select{|c| not c.null and c.type == :boolean}
        code << "  validates_inclusion_of "+cs.collect{|c| ":#{c.name}"}.join(', ')+", in: [true, false]\n" if cs.size > 0 # , :message => 'activerecord.errors.messages.blank'.to_sym

        needed = columns.select{|c| not c.null and c.type != :boolean}.collect{|c| ":#{c.name}"}
        needed += model.reflect_on_all_associations(:belongs_to).select do |association|
          column = model.columns_hash[association.foreign_key.to_s]
          raise StandardError.new("Problem in #{association.active_record.name} at '#{association.macro} :#{association.name}'") if column.nil?
          !column.null and validable_column?(column)
        end.collect{|r| ":#{r.name}"}
        code << "  validates_presence_of "+needed.sort.join(', ')+"\n" if needed.size > 0

        return code
      end

    end
  end
end


desc "Adds default validations in models based on the schema"
task :validations => :environment do
  log = File.open(Rails.root.join("log", "clean-validations.log"), "wb")

  print " - Validations: "

  errors = []
  Clean::Support.models_in_file.each do |model|
    log.write("> #{model.name}...\n")
    begin
      file = Rails.root.join("app", "models", model.name.underscore + ".rb")
      if file.exist? and !model.abstract_class?

        # Get content
        content = nil
        File.open(file, "rb:UTF-8") do |f|
          content = f.read
        end

        # Look for tag
        tag_start = "#[VALIDATORS["
        tag_end = "#]VALIDATORS]"

        regexp = /\ *#{Regexp.escape(tag_start)}[^\A]*#{Regexp.escape(tag_end)}\ */x
        tag = regexp.match(content)

        # Compute (missing) validations
        validations = Clean::Validations.search_missing_validations(model)
        next if validations.blank? and not tag

        # Create tag if it's necessary
        unless tag
          content.sub!(/(class\s#{model.name}\s*<\s*(Ekylibre::Record::Base|ActiveRecord::Base))/, '\1'+"\n  #{tag_start}\n  #{tag_end}")
        end

        # Update tag
        content.sub!(regexp, "  "+tag_start+" Do not edit these lines directly. Use `rake clean:validations`.\n" + validations.to_s + "  "+tag_end)

        # Save file
        File.open(file, "wb") do |f|
          f.write content
        end

      end
    rescue StandardError => e
      errors << e
      log.write("Unable to adds validations on #{class_name}: #{e.message}\n" + e.backtrace.join("\n"))
    end
  end
  print "#{errors.size.to_s.rjust(3)} errors\n"

  log.close
end

desc "Removes the validators contained betweens the tags"
task :empty_validations do
  errors = []
  Dir[Rails.root.join("app", "models", "*.rb")].sort.each do |file|
    class_name = file.split(/\/\\/)[-1].sub(/\.rb$/,'').camelize
    begin

      # Get content
      content = nil
      File.open(file, "rb:UTF-8") do |f|
        content = f.read
      end

      # Look for tag
      tag_start = "#[VALIDATORS["
      tag_end = "#]VALIDATORS]"

      regexp = /\ *#{Regexp.escape(tag_start)}[^\A]*#{Regexp.escape(tag_end)}\ */x
      tag = regexp.match(content)

      # Compute (missing) validations
      next unless tag

      # Update tag
      content.sub!(regexp, "  "+tag_start+"\n  "+tag_end)

      # Save file
      File.open(file, "wb") do |f|
        f.write content
      end
    rescue StandardError => e
      puts "Unable to adds validations on #{class_name}: #{e.message}\n"+e.backtrace.join("\n")
    end
  end
end
