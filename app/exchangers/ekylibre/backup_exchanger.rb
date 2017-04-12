module Ekylibre
  class BackupExchanger < ActiveExchanger::Base
    self.deprecated = true

    class Backup < Hash
      class << self
        def models
          %i[account account_balance area asset asset_depreciation
             bank_statement cash cash_transfer contact cultivation
             custom_field custom_field_choice custom_field_datum delay
             department deposit deposit_line district document
             document_template entity entity_category entity_link
             entity_link_nature entity_nature establishment event
             event_nature financial_year incoming_delivery
             incoming_delivery_line incoming_delivery_mode incoming_payment
             incoming_payment_mode incoming_payment_use inventory
             inventory_line journal journal_entry journal_entry_line
             land_parcel land_parcel_group land_parcel_kinship listing
             listing_node listing_node_item mandate observation
             operation operation_line operation_nature operation_use
             outgoing_delivery outgoing_delivery_line outgoing_delivery_mode
             outgoing_payment outgoing_payment_mode outgoing_payment_use
             preference price product product_category product_component
             production_chain production_chain_conveyor
             production_chain_work_center production_chain_work_center_use
             profession purchase purchase_line purchase_nature role
             sale sale_line sale_nature sequence stock stock_move
             stock_transfer subscription subscription_nature tax
             tax_declaration tool tracking tracking_state transfer
             transport unit user warehouse]
        end

        def schema
          @schema ||= YAML.load_file(Pathname.new(__FILE__).dirname.join('backup', 'schema-0.4.yml')).deep_symbolize_keys.freeze
        end
      end

      attr_reader :matchings

      def self.load(company)
        # x = schema.select do |table, columns|
        #   y = columns.keys.delete_if{|c| [:creator_id, :updater_id, :company_id].include?(c)}.detect{|c| c.to_s =~ /\_id$/}
        #   y
        # end.keys
        # # Root models: (models.map{|m| m.to_s.pluralize.to_sym} - x)
        backup = new
        company.children.each do |rows|
          model = rows.attr(:model).to_sym
          table = model.to_s.pluralize.to_sym
          backup[model] = []
          rows.children.each do |row|
            backup[model] << row.attributes.each_with_object({}) do |pair, hash|
              attribute = pair.first.to_sym
              value = pair.second.to_s
              type = schema[table][attribute][:type].to_sym
              if type == :boolean
                value = (value == 'true' ? true : false)
              elsif type == :integer
                value = (value.blank? ? nil : value.to_i)
              elsif type == :decimal
                value = (value.blank? ? nil : value.to_d)
              elsif type == :date
                value = (value.blank? ? nil : value.to_date)
              elsif type == :datetime
                value = (value.blank? ? nil : value.to_datetime)
              end
              value = nil if value.blank? && type != :boolean
              hash[attribute] = value unless [:company_id].include?(attribute)
              hash
            end.to_struct
          end
        end
        backup
      end

      def initialize(*args)
        super(*args)
        @matchings = {}.with_indifferent_access
        @indexes = {}.with_indifferent_access
      end

      def value_of(item, old_column, references = nil, converter = nil)
        value = nil
        if converter
          value = converter.call(item)
        else
          value = item[old_column]
          if references
            if references =~ /^\~/ && (ref = item[references[1..-1]])
              ref = ref.underscore
              if ref.blank?
                value = nil
              elsif @matchings[ref]
                value = @matchings[ref][value]
              else
                Rails.logger.warn "Cannot match #{ref.inspect} ##{value.inspect} (polymorphic)"
                value = nil
              end
            else
              if @matchings[references]
                value = @matchings[references][value]
              else
                Rails.logger.warn "Cannot find #{references.inspect} ##{value.inspect}"
                value = nil
              end
            end
          end
        end
        value
      end

      def build_index(backup_model, keys)
        @indexes[backup_model] = []
        self[backup_model].each do |item|
          unique_code = keys.collect { |k| item.send(k) }.join('-')
          @indexes[backup_model] << unique_code
        end
      end

      def uniqify_doubles!(backup_model, keys, options = {})
        build_index(backup_model, keys)
        doubles = @indexes[backup_model].size - @indexes[backup_model].uniq.size
        undoubler = options[:undoubler] || keys.reject { |k| k.to_s =~ /(^|\_)id$/ }.last
        unless doubles.zero?
          dones = []
          separator = options[:undoubler_separator] || '-'
          self[backup_model].each do |item|
            unique_code = keys.collect { |k| item.send(k) }.join('-')
            if dones.include?(unique_code)
              prefix = item.send(undoubler)
              undoubler_value = prefix
              counter = 1
              loop do
                undoubler_value = prefix + separator + counter.to_s
                unique_code = keys.collect { |k| k == undoubler ? undoubler_value : item.send(k) }.join('-')
                break unless dones.include?(unique_code)
                counter += 1
              end
              item.send("#{undoubler}=", undoubler_value)
            end
            dones << unique_code
          end
        end
      end

      def import(backup_model, *args)
        # puts "Import #{backup_model.to_s.red}"
        # puts self[backup_model].first.inspect.yellow
        options = args.extract_options!
        keys = args
        keys << :name if keys.empty?
        columns = self.class.schema[backup_model.to_s.pluralize.to_sym].delete_if do |c|
          %i[company_id creator_id updater_id id lock_version].include? c
        end
        keys.each do |key|
          raise "Invalid key for record identification: #{key}" unless columns.include? key
        end
        renamings = columns.keys.each_with_object({}) do |k, h|
          h[k] = { comment: :description, department_id: :team_id }[k] || k
          h
        end
        converters = options.delete(:converters) || {}
        default_values = options[:default_values] || {}
        if options[:rename]
          options[:rename].each do |old_column, new_column|
            raise "What is #{old_column}? #{columns.keys.sort.to_sentence} only are accepted." unless columns.keys.include?(old_column)
            renamings[old_column] = new_column
          end
        end
        model = options[:model] || backup_model
        klass = model.to_s.camelcase.constantize

        # Look for doubles
        uniqify_doubles!(backup_model, keys, options.slice(:undoubler, :undoubler_separator))

        browse_and_match(backup_model) do |item|
          # puts item.inspect.magenta
          finder = keys.each_with_object({}) do |key, hash|
            new_column = renamings[key]
            hash.store(new_column, value_of(item, key, columns[key][:references], converters[new_column]))
            hash
          end
          record = klass.find_by(finder) || klass.new
          attributes = {}
          renamings.each do |old_column, new_column|
            unless new_column.nil?
              attributes[new_column] = value_of(item, old_column, columns[old_column][:references], converters[new_column])
            end
          end
          default_values.each do |new_column, value|
            attributes[new_column] ||= value
          end
          record.attributes = attributes
          unless record.valid?
            Rails.logger.warn attributes.inspect
            Rails.logger.warn record.errors.inspect
          end
          record.save!
          record.id
        end
      end

      def browse_and_match(backup_model)
        @matchings[backup_model] ||= {}
        self[backup_model].each do |item|
          @matchings[backup_model][item.id] = yield(item)
        end
      end
    end

    def import
      # CAUTION Fixed manually by counting points
      # grep -rin check_point app/exchangers/ekylibre/backup_exchanger.rb | wc -l
      w.count = 20 - 1

      # Unzip file
      dir = w.tmp_dir
      Zip::File.open(file) do |zile|
        zile.each do |entry|
          entry.extract(dir.join(entry.name))
        end
      end

      w.check_point

      # Check database
      database = dir.join('backup.xml')
      raise NotWellFormedFileError unless database.exist?

      w.check_point

      #
      f = File.open(database)
      doc = Nokogiri::XML(f) do |config|
        config.strict.nonet.noblanks.noent
      end
      f.close

      w.check_point

      root = doc.root
      unless root.attr(:version).to_s == '20120806083148' # Ekylibre v0.4
        raise NotSupportedFormatError
      end
      data = Backup.load(root.children.first)

      w.check_point

      # :accounts, :cultivations, :custom_fields, :delays, :districts, :document_templates, :entity_categories, :entity_link_natures, :entity_natures, :establishments, :event_natures, :incoming_delivery_modes, :journals, :land_parcel_groups, :listings, :operation_natures, :outgoing_delivery_modes, :production_chains, :professions, :roles, :sequences, :tools, :units

      delays = data[:delay].each_with_object({}) do |item, hash|
        hash[item.id] = item.expression
        hash
      end
      w.check_point

      # Import accounts
      accounting_system = Preference[:accounting_system]
      data.browse_and_match(:account) do |item|
        unless account = Account.find_by(number: item.number)
          reference = Nomen::Account.list.detect do |ref|
            ref.send(accounting_system).to_s == item.number
          end
          account = Account.create!(number: item.number, name: item.name, label: item.label, last_letter: item.last_letter, debtor: item.is_debit, reconcilable: item.reconcilable, usages: (reference ? reference.name : nil), description: item.comment)
        end
        account.id
      end
      w.check_point

      # Import financial_years
      data.import(:financial_year, :code, rename: { last_journal_entry_id: nil })
      w.check_point
      data.import(:department, :name, model: :team, rename: { sales_conditions: nil })
      w.check_point
      data.import(:district, :name, :code)
      w.check_point
      data.import(:journal, :name, converters: {
                    nature: ->(j) { j.nature == 'renew' ? 'forward' : j.nature }
                  })
      w.check_point
      data.import(:sequence, :number_format)
      w.check_point
      data.import(:role, :name, rename: { rights: nil })
      w.check_point
      data[:user].each do |item|
        item.email = item.name + '@ekylibre.org' if item.email.blank?
      end
      password = '12345678'
      data.import(:user, :email, rename: { admin: :administrator, office: nil, profession_id: nil, arrived_on: nil, departed_on: nil, hashed_password: nil, salt: nil, reduction_percent: :maximal_grantable_reduction_percentage, connected_at: :last_sign_in_at, name: nil, rights: nil, establishment_id: nil }, default_values: { password: password, password_confirmation: password })
      w.check_point
      data.import(:entity, :code, rename: { code: :number, category_id: nil, nature_id: nil, payment_delay_id: nil, payment_mode_id: nil, webpass: nil, vat_submissive: :vat_subjected, soundex: nil, salt: nil, hashed_password: nil, invoices_count: nil, origin: :meeting_origin, attorney: nil, attorney_account_id: nil, born_on: :born_at, dead_on: :dead_at, discount_rate: nil, reduction_rate: nil, reflation_submissive: :reminder_submissive, ean13: nil, excise: nil, first_met_on: :first_met_at, website: nil, photo: nil, siren: :siret_number }, default_values: { nature: 'organization' }, converters: { siren: ->(e) { e.siren =~ /\A\d{9}\z/ ? e.siren + Luhn.control_digit(e.siren.to_s + '0001').to_s : e.siren } })
      Entity.where('title ILIKE ? OR title ILIKE ? OR title ILIKE ?', '%Madame%', '%Monsieur%', 'M%').update_all(nature: 'contact')
      w.check_point
      data.import(:cash, :account_id, rename: { account_id: :main_account_id, iban_label: :spaced_iban, address: :bank_agency_address, agency_code: :bank_agency_code, bic: :bank_identifier_code, by_default: nil, entity_id: :owner_id, key: :bank_account_key, number: :bank_account_number })
      w.check_point
      data.import(:bank_statement, :cash_id, :number, rename: { started_on: :started_at, stopped_on: :stopped_at })
      w.check_point
      data.import(:custom_field, :name, rename: { decimal_max: :maximal_value, decimal_min: :minimal_value, length_max: :maximal_length }, default_values: { customized_type: 'Entity' })
      w.check_point
      data.import(:journal_entry, :journal_id, :number, rename: { original_debit: :real_debit, original_credit: :real_credit, original_currency: :real_currency, original_currency_rate: :real_currency_rate, created_on: nil }, undoubler_separator: 'D')
      w.check_point
      data.import(:journal_entry_line, :entry_id, :position, rename: { original_debit: :real_debit, original_credit: :real_credit }, model: :journal_entry_item)
      w.check_point

      # puts (data.keys - data.matchings.keys).inspect.red
    end
  end
end
