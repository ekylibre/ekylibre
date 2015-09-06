# coding: utf-8
module Ekylibre
  module FirstRun
    class Base
      attr_reader :max, :path, :verbose, :mode, :force

      def initialize(path, options = {})
        require 'colored' unless defined? Colored

        @verbose = !options[:verbose].is_a?(FalseClass)
        @force = options[:force].is_a?(TrueClass)
        @mode = options[:mode].to_s.downcase
        @mode = 'normal' if @mode.blank?
        @mode = @mode.to_sym
        @path = path
        unless @path.exist?
          fail ArgumentError, "Need a valid folder path. #{@path} doesn't exist."
        end
        @term_width = begin
                        `/usr/bin/env tput cols`.to_i
                      rescue
                        80
                      end
        @term_width = 80 unless @term_width > 0
        ::I18n.locale = Preference[:language]
        @max = options[:max].to_i
      end

      # Compute a path for first run directory
      def path(*args)
        @path.join(*args)
      end

      def hard?
        @mode == :hard || Rails.env.production?
      end

      def import_pictures(base, type, identifier, _options = {})
        if path("#{base}/pictures").exist?
          file = path("#{base}/pictures.zip")
          FileUtils.rm_rf file

          mimefile = path.join("#{base}/pictures.mimetype")
          File.write(mimefile, "application/vnd.ekylibre.pictures.#{type}")

          idenfile = path.join("#{base}/pictures.identifier")
          File.write(idenfile, identifier.to_s)

          files = {
            'mimetype' => 'pictures.mimetype',
            'identifier' => 'pictures.identifier'
          }
          Dir.chdir(path("#{base}")) do
            Dir.glob('pictures/*').each do |picture|
              p = Pathname.new(picture).basename.to_s
              files[picture] = "pictures/#{p}"
            end
          end
          check_archive(:ekylibre_pictures, file, files.merge(in: "#{base}"))

          FileUtils.rm_f mimefile
          FileUtils.rm_f idenfile
        end
        import_file(:ekylibre_pictures, "#{base}/pictures.zip")
      end

      def import_file(nature, file, options = {})
        p = path(file)
        if p.exist?
          import(nature, p, options)
        elsif @verbose
          text = ["∅ #{nature.to_s.humanize} (#{p.basename})"]
          if text.join.length < @term_width
            text << ' ' * (@term_width - text.join.length)
          end
          text[0] = text[0].yellow
          puts text.join
        end
      end

      def import_archive(nature, target, *files)
        if file = check_archive(nature, target, *files)
          import_file(nature, file)
        end
      end

      # Check that archive exist if not try to build one if existing file
      # Given files must exist
      def check_archive(nature, target, *files)
        files.flatten!
        options = files.extract_options!
        working_path = @path.join(options[:in] ? options.delete(:in) : '.')
        prevent = options.delete(:prevent).is_a?(FalseClass)
        target_path = working_path.join(target)
        map = options
        files.each { |file| map[file] = file }
        map.each do |dest, source|
          map[dest] = working_path.join(source)
        end
        FileUtils.rm_rf(target_path) if target_path.exist?
        expected = map.values.select { |source| !source.exist? }
        if expected.any?
          if expected.size != map.values.size
            puts "☠ #{nature.to_s.humanize} (#{target})".red
            puts ("  Missing files to build #{target} archive: " + expected.map { |f| f.relative_path_from(@path) }.to_sentence).red
            return false
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
            ::Kernel.exit 1
          end
        end
        # end
        target_path
      end

      # Import a given file
      def import!(nature, file, options = {})
        # puts "> import(:#{nature.to_s}, '#{file.to_s}', #{options.inspect})"
        last = ''
        start = Time.now
        basename = nature.to_s.humanize + ' (' + Pathname.new(file).basename.to_s + ') '
        total = 0
        max = options[:max] || @max
        Import.launch!(nature, file) do |progress, count|
          if @verbose
            status = [basename]
            status << " #{progress.to_i}%"
            if progress > 0
              remaining = (100 - progress) * (Time.now - start) / progress
              status << " #{remaining.round.to_i}s"
            end
            l = @term_width - status.join.length
            if l > 0
              status.insert(1, '|' * l)
            elsif l < 0
              status[0] = basename[0..(l - 4)] + '...'
            end
            line = status.join
            done = (progress * @term_width / 100.0).round.to_i
            done = @term_width if done > @term_width
            print "\r" * last.size + line[0..done].green + (done == @term_width ? '' : line[(done + 1)..-1])
            last = line
            total = count
          end
          max <= 0 || count < max
        end
        if @verbose
          stop = Time.now
          status = [basename]
          status << ' ' + total.to_s
          status << ' done in '
          status << "#{(stop - start).to_i}s"
          l = @term_width - status.join.length
          n = 0
          if l > 0
            status.insert(1 + n, ' ' * l)
            status[2 + n] = status[2 + n].blue
            status[4 + n] = status[4 + n].blue
          elsif l < 0
            status[0 + n] = basename[0..(l - 4)] + '...'
            status[1 + n] = status[1 + n].blue
            status[3 + n] = status[3 + n].blue
          end
          status[1] = status[1].green
          status[0 + n] = status[0 + n].blue
          puts "\r" * last.size + status.join
        end
      end

      def import(nature, file, options = {})
        import!(nature, file, options)
      end

      def self.ellipse(text, size = 32)
        ellipsis = '...'
        if text.size > size
          first = ((size - ellipsis.size).to_f / 2).round
          return text[0..(first - 1)] + ellipsis + text[-(size - first - ellipsis.size)..-1]
        end
        text
      end
    end
  end
end
