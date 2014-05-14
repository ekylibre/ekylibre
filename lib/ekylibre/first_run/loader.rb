# -*- coding: utf-8 -*-
module Ekylibre
  module FirstRun

    class Loader
      attr_reader :folder
      
      def initialize(folder, options = {})
        @folder = folder.to_s
        @folder_path = Ekylibre::FirstRun.path.join(@folder)
        @max = (options[:max] || ENV["max"]).to_i
        @max = COUNTER_MAX if @max.zero?
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
        f = Counter.new(@max)
        start = Time.now
        label_size = options[:label_size] || 21
        label = name.to_s.humanize.rjust(label_size)
        ellipsis = "…"
        if label.size > label_size
          first = ((label_size - ellipsis.size).to_f / 2).round
          label = label[0..(first-1)] + ellipsis + label[-(label_size - first - ellipsis.size)..-1]
        end
        print "[#{@folder.green}] #{label.blue}: "
        begin
          yield(f)
          print " " * (@max - f.count) if @max != COUNTER_MAX and f.count < @max
          print "  "
        rescue CountExceeded => e
          print "! "
        end
        puts "#{(Time.now - start).round(2).to_s.rjust(6)}s"
      end

    end
  end
end
