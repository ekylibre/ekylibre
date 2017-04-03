module Ekylibre
  module FirstRun
    class Folder
      VERSION = 2

      attr_reader :path, :version, :imports, :preferences, :defaults, :verbose

      def initialize(path, options = {})
        @verbose = !options[:verbose].is_a?(FalseClass)
        @path = Pathname.new(path)
        manifest = YAML.load_file(@path.join('manifest.yml')).deep_symbolize_keys
        @version = manifest[:version]
        unless @version == VERSION
          raise "Incompatible first-run folder: #{@version.inspect}." \
                "Need v#{VERSION} first-run API."
        end
        @company = manifest[:company] || {}
        @imports = manifest[:imports] || {}
        @preferences = manifest[:preferences] || {}
        @defaults = manifest[:defaults] || {}
      end

      def imports_dir
        @path.join('imports')
      end

      def run
        ActiveRecord::Base.transaction do
          puts 'Set locale...'
          ::I18n.locale = @preferences[:language] || :eng
          puts 'Load preferences...'
          load_preferences
          puts 'Load defaults...'
          load_defaults
          puts 'Load company...'
          load_company
          puts 'Load imports...'
          load_imports
          puts 'Save state...'
          ::Preference.set!('first_run.executed', false, :boolean)
        end
      end

      # Load global preferences of the instance
      def load_preferences
        @preferences[:map_measure_srs] ||= 'WGS84'
        @preferences.each do |key, value|
          if Preference.reference[key]
            Preference.set!(key, value)
          else
            Rails.logger.warn "Unknown preference: #{key}"
          end
        end
      end

      # Load default data of models with default data
      def load_defaults
        %i[sequences accounts document_templates taxes journals cashes
           sale_natures purchase_natures incoming_payment_modes
           outgoing_payment_modes product_nature_variants map_layers].each do |dataset|
          next if @defaults[dataset].is_a?(FalseClass)
          puts "Load default #{dataset}..."
          model = dataset.to_s.classify.constantize
          model.load_defaults
        end
      end

      # Load company informations (entity) and its activities
      def load_company
        company = Entity.find_or_initialize_by(of_company: true, nature: :organization)
        company.last_name = @company[:name]
        company.born_at = @company[:born_at]
        company.save!
        # Create default phone number
        if @company[:phone].present?
          phone = company.phones.find_or_initialize_by(by_default: true)
          phone.coordinate = @company[:phone]
          phone.save!
        end
        # Create default mail address
        unless @company[:mail_line_4].blank? && @company[:mail_line_6].blank?
          mail = company.mails.find_or_initialize_by(by_default: true)
          mail.mail_line_4 = @company[:mail_line_4]
          mail.mail_line_6 = @company[:mail_line_6]
          mail.save!
        end
        load_users(@company[:users]) if @company[:users]
      end

      # Load all given imports directly (to ensure given order)
      def load_imports
        @imports.each do |name, import|
          import[:nature] ||= name
          puts "Import #{import[:nature].to_s.yellow} from #{import[:file].to_s.blue}"
          Import.launch!(import[:nature], path.join('imports', import[:file]))
        end
      end

      # Load (administrator) users
      def load_users(users = {})
        users.each do |email, attributes|
          defaults = {
            email: email,
            first_name: 'John',
            last_name: 'Doe',
            password: '12345678',
            administrator: true
          }
          unless User.find_by(email: email)
            User.create!(defaults.merge(attributes))
          end
        end
      end

      protected

      def warn(message)
        Rails.logger.warn(message)
      end
    end
  end
end
