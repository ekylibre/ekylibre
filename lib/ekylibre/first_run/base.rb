# coding: utf-8

module Ekylibre
  module FirstRun
    class Base
      LOADERS = YAML.load_file(Pathname.new(__FILE__).dirname.join('loaders.yml')).deep_symbolize_keys.freeze

      attr_reader :max, :path, :verbose, :mode, :force

      def initialize(path, options = {})
        @verbose = !options[:verbose].is_a?(FalseClass)
        @force = options[:force].is_a?(TrueClass)
        @mode = options[:mode].to_s.downcase
        @mode = 'normal' if @mode.blank?
        @mode = @mode.to_sym
        @path = path
        unless @path.exist?
          raise ArgumentError, "Need a valid folder path. #{@path} doesn't exist."
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

      def executed_preference
        Preference.get('first_run.executed', false)
      end

      # Execute all loaders for a given base
      def run
        secure_transaction(!hard?) do
          preference = executed_preference
          LOADERS.each do |loader, imports|
            run_loader(loader, imports)
          end
          preference.value = true
          preference.save!
        end
      end

      # Execute given loader for a given base
      def run_loader(loader, imports)
        ::I18n.locale = Preference[:language]
        ActiveRecord::Base.transaction do
          preference = Preference.get("first_run.executed_loaders.#{loader}", false)
          if force || !preference.value
            # @loaders[loader].call(base)
            imports.each do |import_name, options|
              format = options[:format] || :file
              path = options[:path]
              nature = options[:type] || import_name
              if format == :archive
                import_archive(nature, path, options[:files], options.slice(:in, :mimetype))
              elsif format == :pictures
                import_pictures(path, options[:table], options[:id_column])
              elsif format == :file
                import_file(nature, path, options)
              else
                raise 'Cannot import that format: ' + format.inspect
              end
            end
            preference.value = true
            preference.save!
          else
            puts 'Skip'.yellow + " #{loader} loader"
          end
        end
      end

      # Wrap code in a transaction if wanted
      def secure_transaction(with_transaction = true, &block)
        (with_transaction ? ActiveRecord::Base.transaction(&block) : yield)
      end

      def import_pictures(base, type, identifier)
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
          Dir.chdir(path(base.to_s)) do
            Dir.glob('pictures/*').each do |picture|
              p = Pathname.new(picture).basename.to_s
              files[picture] = "pictures/#{p}"
            end
          end
          check_archive(:ekylibre_pictures, file, files, in: base.to_s)

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
          text = [" ∅ #{nature.to_s.humanize}", " (#{p.basename})"]
          if text.join.length < @term_width
            text << ' ' * (@term_width - text.join.length)
          end
          text[0] = text[0].yellow
          puts text.join
        end
      end

      def import_archive(nature, target, files, options = {})
        file = check_archive(nature, target, files, options)
        import_file(nature, file) if file
      end

      # Check that archive exist if not try to build one if existing file
      # Given files must exist
      def check_archive(nature, target, files, options = {})
        working_path = @path.join(options[:in] ? options.delete(:in) : '.')
        target_path = working_path.join(target)
        files = files.each_with_object({}) { |f, h| h[f] = f } if files.is_a?(Array)
        files.each do |dest, source|
          files[dest] = working_path.join(source)
        end
        files_count = files.keys.count
        mimefile = working_path.join('mimetype')
        FileUtils.rm_rf(target_path) if target_path.exist?
        not_found = files.values.reject(&:exist?)
        if not_found.any?
          if not_found.size != files_count
            puts " ☠ #{nature.to_s.humanize} (#{target})".red
            puts ("   Missing files to build #{target} archive: " + not_found.map { |f| f.relative_path_from(@path) }.to_sentence).red
            return false
          end
        else
          if options[:mimetype]
            FileUtils.mkdir_p(mimefile.dirname)
            File.write(mimefile, options[:mimetype])
            files['mimetype'] = mimefile
          end
          begin
            Zip::File.open(target_path, Zip::File::CREATE) do |zile|
              files.each do |dest, source|
                zile.add(dest, source)
              end
            end
          # Zip Library can throw an us-ascii string error with utf-8 inside
          rescue Exception => e
            puts "Cannot create #{target_path}".red
            puts "Caused by: #{e.to_s.force_encoding('utf-8')}".blue
            ::Kernel.exit 1
          ensure
            FileUtils.rm_rf(mimefile) if options[:mimetype]
          end
        end
        target_path
      end

      # Import a given file
      def import!(nature, file, options = {})
        # puts "> import(:#{nature.to_s}, '#{file.to_s}', #{options.inspect})"
        last = ''
        start = Time.zone.now
        basename = nature.to_s.humanize + ' (' + Pathname.new(file).basename.to_s + ') '
        total = 0
        max = options[:max] || @max
        Import.launch!(nature, file) do |progress, count|
          if @verbose
            status = [' + ' + basename]
            status << " #{progress.to_i}%"
            if progress > 0
              remaining = (100 - progress) * (Time.zone.now - start) / progress
              status << " #{remaining.round.to_i}s"
            end
            l = @term_width - status.join.length
            if l > 0
              status.insert(1, '|' * l)
            elsif l < 0
              status[0] = ' + ' + basename[0..(l - 4)] + '...'
            end
            line = status.join
            done = (progress * @term_width / 100.0).round.to_i
            done = @term_width if done > @term_width
            print "\r" * last.size + line[0..done].blue + (done == @term_width ? '' : line[(done + 1)..-1])
            last = line
            total = count
          end
          max <= 0 || count < max
        end
        if @verbose
          stop = Time.zone.now
          status = [' ✔ ' + nature.to_s.humanize, ' (' + Pathname.new(file).basename.to_s + ') ']
          status << ' ' + total.to_s
          status << ' done in '
          status << "#{(stop - start).to_i}s"
          l = @term_width - status.join.length
          n = 1
          if l > 0
            status.insert(1 + n, ' ' * l)
            status[2 + n] = status[2 + n].green
            status[4 + n] = status[4 + n].green
          elsif l < 0
            status[0] = status[0][0..(l - 4)] + '...'
            status[1 + n] = status[1 + n].green
            status[3 + n] = status[3 + n].green
          end
          status[0] = status[0].green
          # status[1] = status[1].green
          # status[0 + n] = status[0 + n].green
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
