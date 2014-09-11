# -*- coding: utf-8 -*-
module Ekylibre
  module FirstRun

    class Base

      def initialize(options = {})
        @mode = options[:mode].to_s.downcase
        @mode = "normal" if @mode.blank?
        @mode = @mode.to_sym
        @name = (options[:name] || "demo").to_s
        @folder = options[:folder] || @name
        @folder_path = Ekylibre::FirstRun.path.join(@folder)
        file = path("manifest.yml")
        @manifest = (file.exist? ? YAML.load_file(file).deep_symbolize_keys : {})
        @manifest[:company]      ||= {}
        @manifest[:net_services] ||= {}
        @manifest[:identifiers]  ||= {}
        @manifest[:language]     ||= I18n.default_locale
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
        ellipsis = "…"
        if label.size > label_size
          first = ((label_size - ellipsis.size).to_f / 2).round
          label = label[0..(first-1)] + ellipsis + label[-(label_size - first - ellipsis.size)..-1]
        end
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

      # Launch the execution of the loaders
      def launch
        unless Ekylibre::Tenant.exist?(@name)
          Ekylibre::Tenant.create(@name)
        end
        Ekylibre::Tenant.switch(@name)

        if hard? or Rails.env.production?
          puts "No global transaction".red unless options[:quiet]
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

    end
  end
end
