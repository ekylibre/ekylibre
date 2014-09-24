# -*- coding: utf-8 -*-
module Ekylibre
  module FirstRun

    class Base

      def initialize(options = {})
        @mode = options[:mode].to_s.downcase
        @mode = "normal" if @mode.blank?
        @mode = @mode.to_sym
        @name = (options[:name] || options[:folder] || "demo").to_s
        @folder = options[:folder] || @name
        @folder_path = Ekylibre::FirstRun.path.join(@folder)
        file = path("manifest.yml")
        @manifest = (file.exist? ? YAML.load_file(file).deep_symbolize_keys : {})
        @manifest[:company]      ||= {}
        @manifest[:net_services] ||= {}
        @manifest[:identifiers]  ||= {}
        @manifest[:language]     ||= ::I18n.default_locale
        ::I18n.locale = @manifest[:language]
        @max = options[:max].to_i
        @records = {}.with_indifferent_access
      end

      def [](key)
        @manifest[key]
      end

      def []=(key, value)
        @manifest[key] = value
      end

      def manifest
        unless @manifest
          file = path("manifest.yml")
          @manifest = (file.exist? ? YAML.load_file(file).deep_symbolize_keys : {})
          @manifest[:company] ||= {}
          @manifest[:net_services] ||= {}
          @manifest[:identifiers] ||= {}
        end
        return @manifest
      end

      def can_load?(key)
        !@manifest[key].is_a?(FalseClass)
      end

      def can_load_default?(key)
        can_load?(key) and !@manifest[key].is_a?(Hash)
      end

      def create_from_manifest(records, *args)
        options = args.extract_options!
        main_column = args.shift || :name
        model = records.to_s.classify.constantize
        if data = @manifest[records]
          @records[records] ||= {}.with_indifferent_access
          unless data.is_a?(Hash)
            raise "Cannot load #{records}: Hash expected, got #{records.class.name} (#{records.inspect})"
          end
          for identifier, attributes in data
            attributes = attributes.with_indifferent_access
            attributes[main_column] ||= identifier.to_s
            for reflection in model.reflections.values
              if attributes[reflection.name] and not attributes[reflection.name].class < ActiveRecord::Base
                attributes[reflection.name] = get(reflection.class_name.tableize, attributes[reflection.name].to_s)
              end
            end
            @records[records][identifier] = model.create!(attributes)
          end
        end
      end

      # Returns the record corresponding to the identifier
      def get(records, identifier)
        if @records[records]
          return @records[records][identifier]
        end
        return nil
      end

      # Compute a path for first run directory
      def path(*args)
        return @folder_path.join(*args)
      end

      def count(name, options = {}, &block)
        STDOUT.sync = true
        f = Counter.new(@max) do |count, increment|
          print "."
        end
        start = Time.now
        label_size = options[:label_size] || 21
        label = name.to_s.humanize.rjust(label_size)
        label = self.class.ellipse(label, label_size)
        # ellipsis = "…"
        # if label.size > label_size
        #   first = ((label_size - ellipsis.size).to_f / 2).round
        #   label = label[0..(first-1)] + ellipsis + label[-(label_size - first - ellipsis.size)..-1]
        # end
        print "[#{@name.green}] #{label.blue}: "
        begin
          yield(f)
          print " " * (@max - f.count) if 0 < @max and @max > f.count
          print "  "
        rescue Counter::CountExceeded => e
          print "! "
        end
        puts "#{(Time.now - start).round(2).to_s.rjust(6)}s"
      end

      def hard?
        @mode == :hard
      end


      # Check that archive exist if not try to build one if existing file
      # Given files must exist
      def check_archive(target, *files)
        files.flatten!
        options = files.extract_options!
        working_path = @folder_path.join(options[:in] ? options.delete(:in) : ".")
        target_path = working_path.join(target)
        map = options
        files.each { |file| map[file] = file }
        map.each do |dest, source|
          map[dest] = working_path.join(source)
        end
        if target_path.exist?
          expected = map.keys.map(&:to_s)
          Zip::File.open(target_path) do |zile|
            zile.each do |entry|
              expected.delete(entry.name)
            end
          end
          if expected.any?
            raise "Missing files in archive #{target}: #{expected.to_sentence}"
          end
        else
          expected = map.values.select{|source| !source.exist?}
          if expected.any?
            if expected.size != map.values.size
              raise "Missing files to build #{target} archive: #{expected.to_sentence}"
            end
          else
            begin
              Zip::File.open(target_path, Zip::File::CREATE) do |zile|
                map.each do |dest, source|
                  zile.add(dest, source)
                end
              end
            # Zip Library can throw an us-ascii string error with utf-8 inside
            rescue Exception => e
              puts "Cannot create #{target_path}".red
              puts "Caused by: #{e.to_s.force_encoding('utf-8')}".blue
              System.exit 1
            end
          end
        end
        return target_path
      end


      # Import a given file
      def import(nature, file)
        last = ""
        start = Time.now
        length = %x{stty size}.split[1].to_i
        basename = nature.to_s.humanize+ " (" + Pathname.new(file).basename.to_s + ") "
        total = 0
        Import.launch!(nature, file) do |progress, count|
          status = [basename]
          status << " #{progress.to_i}%"
          if progress > 0
            remaining = (100 - progress) * (Time.now - start) / progress
            status << " #{remaining.round.to_i}s"
          end
          l = length - status.join.length
          if l > 0
            status.insert(1, "|" * l)
          elsif l < 0
            status[0] = basename[0..(l - 4)] + "..."
          end
          line = status.join
          done = (progress * length / 100.0).round.to_i
          done = length if done > length
          print "\r" * last.size + line[0..done].green + (done == length ? "" : line[(done+1)..-1])
          last = line
          total = count
          @max <= 0 or count <= @max
        end
        stop = Time.now
        status = [basename]
        status << " " + total.to_s
        status << " done in "
        status << "#{(stop - start).to_i}s"
        l = length - status.join.length
        if l > 0
          status.insert(1, " " * l)
          status[2] = status[2].blue
          status[4] = status[4].blue
        elsif l < 0
          status[0] = basename[0..(l - 4)] + "..."
          status[1] = status[1].blue
          status[3] = status[3].blue
        end
        status[0] = status[0].blue
        puts "\r" * last.size + status.join
      end

      # Launch the execution of the loaders
      def launch
        if hard? or Rails.env.production?
          puts "No global transaction".red
          execute
        else
          ActiveRecord::Base.transaction do
            execute
          end
        end
      end

      private

      # Execute a suite of loaders in the given order
      def execute(*loaders)
        Ekylibre::Tenant.check!(@name)
        unless Ekylibre::Tenant.exist?(@name)
          Ekylibre::Tenant.create(@name)
        end
        Ekylibre::Tenant.switch(@name)

        loaders = Ekylibre::FirstRun.loaders if loaders.empty?

        for loader in loaders
          execute_loader(loader)
        end
      end

      # Execute a loader in transactionnal mode
      def execute_loader(name)
        ActiveRecord::Base.transaction do
          puts "Load #{name.to_s.red}:"
          Ekylibre::FirstRun.call_loader(name, self)
        end
      end

      def self.ellipse(text, size = 32)
        ellipsis = "..."
        if text.size > size
          first = ((size - ellipsis.size).to_f / 2).round
          return text[0..(first-1)] + ellipsis + text[-(size - first - ellipsis.size)..-1]
        end
        return text
      end

    end
  end
end
