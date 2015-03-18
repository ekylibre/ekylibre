# coding: utf-8
module Ekylibre
  module FirstRun

    class Base

      attr_reader :max

      def initialize(options = {})
	      require 'ffaker' unless defined? Faker
	      require 'colored' unless defined? Colored

        @verbose = !options[:verbose].is_a?(FalseClass)
        @mode = options[:mode].to_s.downcase
        @mode = "normal" if @mode.blank?
        @mode = @mode.to_sym
        if options[:path] and options[:folder]
          raise ArgumentError, ":path and :folder options are incompatible"
        end
        @name = options[:name] || options[:folder]
        if options[:path]
          @folder_path = Pathname.new(options[:path])
          @folder = @folder_path.basename.to_s
          @name ||= @folder
        else
          @name ||= "demo" if Ekylibre::FirstRun.path.join("demo").exist?
          @name ||= "default" if Ekylibre::FirstRun.path.join("default").exist?
          @folder = options[:folder] || @name
          @folder_path = Ekylibre::FirstRun.path.join(@folder)
        end
        unless @folder_path.exist?
          raise ArgumentError, "Need a valid folder path. #{@folder_path} doesn't exist."
        end
        @term_width = %x{echo $-}.strip =~ /i/ ? %{stty size}.split[1].to_i : 80
        ::I18n.locale = Preference[:language]
        @max = options[:max].to_i
      end

      # Compute a path for first run directory
      def path(*args)
        return @folder_path.join(*args)
      end

      def hard?
        @mode == :hard
      end

      def import_pictures(base, type, identifier, options = {})
        if path("#{base}/pictures").exist?
          file = path("#{base}/pictures.zip")
          FileUtils.rm_rf file
          
          mimefile = path.join("#{base}/pictures.mimetype")
          File.write(mimefile, "application/vnd.ekylibre.pictures.#{type}")

          idenfile = path.join("#{base}/pictures.identifier")
          File.write(idenfile, identifier.to_s)
          
          files = {
            "mimetype" => "pictures.mimetype",
            "identifier" => "pictures.identifier"
          }
          Dir.chdir(path("#{base}")) do
            Dir.glob("pictures/*").each do |picture|
              p = Pathname.new(picture).basename.to_s
              files[picture] = "pictures/#{p}"
            end
          end
          check_archive(file, files.merge(in: "#{base}"))

          FileUtils.rm_f mimefile
          FileUtils.rm_f idenfile
        end
        import_file(:ekylibre_pictures, "#{base}/pictures.zip")
      end
      
      def import_file(nature, file, options = {})
        p = self.path(file)
        if p.exist?
          self.import(nature, p, options)
        elsif @verbose
          text = ["[", @name, "] ", "#{nature.to_s.humanize} (#{p.basename})"]
          text << " " * (@term_width - text.join.length)
          text[1] = text[1].yellow
          text[3] = text[3].red
          puts text.join
        end
      end
      
      def import_archive(nature, target, *files)
        file = check_archive(target, *files)
        import_file(nature, file)
      end
      
      # Check that archive exist if not try to build one if existing file
      # Given files must exist
      def check_archive(target, *files)
        files.flatten!
        options = files.extract_options!
        working_path = @folder_path.join(options[:in] ? options.delete(:in) : ".")
        prevent = options.delete(:prevent).is_a?(FalseClass)
        target_path = working_path.join(target)
        map = options
        files.each { |file| map[file] = file }
        map.each do |dest, source|
          map[dest] = working_path.join(source)
        end
        if target_path.exist?
          FileUtils.rm_rf(target_path)
        end
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
            ::Kernel.exit 1
          end
        end
        # end
        return target_path
      end


      # Import a given file
      def import!(nature, file, options = {})
        # puts "> import(:#{nature.to_s}, '#{file.to_s}', #{options.inspect})"
        last = ""
        start = Time.now
        basename = nature.to_s.humanize+ " (" + Pathname.new(file).basename.to_s + ") "
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
              status.insert(1, "|" * l)
            elsif l < 0
              status[0] = basename[0..(l - 4)] + "..."
            end
            line = status.join
            done = (progress * @term_width / 100.0).round.to_i
            done = @term_width if done > @term_width
            print "\r" * last.size + line[0..done].green + (done == @term_width ? "" : line[(done+1)..-1])
            last = line
            total = count
          end
          max <= 0 or count < max
        end
        if @verbose
          stop = Time.now
          status = ["[", @name, "] ", basename]
          status << " " + total.to_s
          status << " done in "
          status << "#{(stop - start).to_i}s"
          l = @term_width - status.join.length
          n = 3
          if l > 0
            status.insert(1 + n, " " * l)
            status[2 + n] = status[2 + n].blue
            status[4 + n] = status[4 + n].blue
          elsif l < 0
            status[0 + n] = basename[0..(l - 4)] + "..."
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

      # Launch the execution of the loaders
      def launch
        Rails.logger.info "Import first run of #{@name} from #{@folder_path.to_s} in #{@mode} mode " + (@max > 0 ? "with max of #{@max}" : 'without max') + "."
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

        loaders = Ekylibre::FirstRun.loaders if loaders.empty?

        Ekylibre::Tenant.switch(@name)
        loaders.each do |loader|
          execute_loader(loader)
        end
      ensure
        Ekylibre::Tenant.check!(@name)
      end

      # Execute a loader in transactional mode
      def execute_loader(name)
        ::I18n.locale = Preference[:language]
        ActiveRecord::Base.transaction do
          # puts "Load #{name.to_s.red}:"
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
