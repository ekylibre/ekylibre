namespace :clean do
  desc 'Adds default validations in models based on the schema'
  task validations: :environment do
    log = File.open(Rails.root.join('log', 'clean-validations.log'), 'wb')
    Clean::Support.set_search_path!

    print ' - Validations: '

    errors = []
    Clean::Support.models_in_file.each do |model|
      log.write("> #{model.name}...\n")
      begin
        file = Rails.root.join('app', 'models', "#{model.name.underscore}.rb")
        if file.exist? && !model.abstract_class?

          # Get content
          content = nil
          File.open(file, 'rb:UTF-8') do |f|
            content = f.read
          end

          # Look for tag
          tag_start = '# [VALIDATORS['
          tag_end = '# ]VALIDATORS]'

          regexp = /\ *#{Regexp.escape(tag_start)}[^\A]*#{Regexp.escape(tag_end)}\ */x
          tag = regexp.match(content)

          # Compute (missing) validations
          validations = Clean::Validations.search_missing_validations(model)
          next if validations.blank? && !tag

          # Create tag if it's necessary
          unless tag
            content.sub!(/(class\s#{model.name}\s*<\s*(Ekylibre::Record::Base|ActiveRecord::Base))/, '\1' + "\n  #{tag_start}\n  #{tag_end}")
          end

          # Update tag
          content.sub!(regexp, '  ' + tag_start + " Do not edit these lines directly. Use `rake clean:validations`.\n" + validations.to_s + '  ' + tag_end)

          # Save file
          File.open(file, 'wb') do |f|
            f.write content
          end

        end
      rescue StandardError => e
        errors << e
        log.write("Unable to adds validations on #{model.name}: #{e.message}\n" + e.backtrace.join("\n"))
      end
    end
    print "#{errors.size.to_s.rjust(3)} errors\n"

    log.close
  end

  namespace :validations do
    desc 'Removes the validators contained betweens the tags'
    task :empty do
      Clean::Support.set_search_path!
      errors = []

      Dir[Rails.root.join('app', 'models', '*.rb')].sort.each do |file|
        class_name = file.split(/\/\\/)[-1].sub(/\.rb$/, '').camelize
        begin
          # Get content
          content = nil
          File.open(file, 'rb:UTF-8') do |f|
            content = f.read
          end

          # Look for tag
          tag_start = '# [VALIDATORS['
          tag_end = '# ]VALIDATORS]'

          regexp = /\ *#{Regexp.escape(tag_start)}[^\A]*#{Regexp.escape(tag_end)}\ */x
          tag = regexp.match(content)

          # Compute (missing) validations
          next unless tag

          # Update tag
          content.sub!(regexp, '  ' + tag_start + "\n  " + tag_end)

          # Save file
          File.open(file, 'wb') do |f|
            f.write content
          end
        rescue StandardError => e
          puts "Unable to adds validations on #{class_name}: #{e.message}\n" + e.backtrace.join("\n")
        end
      end
    end
  end
end
