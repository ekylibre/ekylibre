# Import a backup
Exchanges.add_importer :ekylibre_backup do |file, w|

  class Backup < Hash

    MODELS = [:account, :account_balance, :area, :asset, :asset_depreciation, :bank_statement, :cash, :cash_transfer, :contact, :cultivation, :custom_field, :custom_field_choice, :custom_field_datum, :delay, :department, :deposit, :deposit_line, :district, :document, :document_template, :entity, :entity_category, :entity_link, :entity_link_nature, :entity_nature, :establishment, :event, :event_nature, :financial_year, :incoming_delivery, :incoming_delivery_line, :incoming_delivery_mode, :incoming_payment, :incoming_payment_mode, :incoming_payment_use, :inventory, :inventory_line, :journal, :journal_entry, :journal_entry_line, :land_parcel, :land_parcel_group, :land_parcel_kinship, :listing, :listing_node, :listing_node_item, :mandate, :observation, :operation, :operation_line, :operation_nature, :operation_use, :outgoing_delivery, :outgoing_delivery_line, :outgoing_delivery_mode, :outgoing_payment, :outgoing_payment_mode, :outgoing_payment_use, :preference, :price, :product, :product_category, :product_component, :production_chain, :production_chain_conveyor, :production_chain_work_center, :production_chain_work_center_use, :profession, :purchase, :purchase_line, :purchase_nature, :role, :sale, :sale_line, :sale_nature, :sequence, :stock, :stock_move, :stock_transfer, :subscription, :subscription_nature, :tax, :tax_declaration, :tool, :tracking, :tracking_state, :transfer, :transport, :unit, :user, :warehouse]

    SCHEMA = YAML.load_file(Pathname.new(__FILE__).dirname.join("backup", "schema-0.4.yml")).deep_symbolize_keys.freeze

    attr_reader :matchings

    def self.load(company)
      # x = SCHEMA.select do |table, columns|
      #   y = columns.keys.delete_if{|c| [:creator_id, :updater_id, :company_id].include?(c)}.detect{|c| c.to_s =~ /\_id$/}
      #   y
      # end.keys
      # # Root models: (MODELS.map{|m| m.to_s.pluralize.to_sym} - x)
      backup = new
      company.children.each do |rows|
        model = rows.attr(:model).to_sym
        table = model.to_s.pluralize.to_sym
        backup[model] = []
        rows.children.each do |row|
          backup[model] << row.attributes.inject({}) do |hash, pair|
            attribute = pair.first.to_sym
            value = pair.second.to_s
            if SCHEMA[table] and SCHEMA[table][attribute] and type = SCHEMA[table][attribute][:type].to_sym
              if type == :boolean
                value = (value == "true" ? true : false)
              elsif type == :integer
                value = (value.blank? ? nil : value.to_i)
              elsif type == :decimal
                value = (value.blank? ? nil : value.to_d)
              elsif type == :date
                value = (value.blank? ? nil : value.to_date)
              elsif type == :datetime
                value = (value.blank? ? nil : value.to_datetime)
              end
            elsif attribute.to_s =~ /(^|\_)id$/
              value = value.to_i
              value = nil if value.zero?
            end
            # value = nil if value.blank?
            unless [:company_id].include?(attribute)
              hash[attribute] = value
            end
            hash
          end.to_struct
        end
      end
      return backup
    end


    def initialize(*args)
      super(*args)
      @matchings = {}.with_indifferent_access
    end


    def value_of(item, old_column, references = nil, converter = nil)
      value = nil
      if converter
        value = converter.call(item)
      else
        value = item[old_column]
        if references
          if references =~ /^\~/ and ref = item[references[1..-1]]
            ref = ref.underscore
            if ref.blank?
              value = nil
            elsif @matchings[ref]
              value = @matchings[ref][value]
            else
              raise "Cannot match #{ref.inspect} (polymorphic)"
            end
          else
            if @matchings[references]
              value = @matchings[references][value]
            else
              raise "Cannot match #{references.inspect}"
            end
          end
        end
      end
      return value
    end

    def import(backup_model, *args)
      # puts "Import #{backup_model.to_s.red}"
      # puts self[backup_model].first.inspect.yellow
      options = args.extract_options!
      keys = args
      keys << :name if keys.empty?
      columns = SCHEMA[backup_model.to_s.pluralize.to_sym].delete_if do |c|
        [:company_id, :creator_id, :updater_id, :id, :lock_version].include? c
      end
      keys.each do |key|
        raise "Invalid key for record identification: #{key}" unless columns.include? key
      end
      renamings = columns.keys.inject({}) do |h, k|
        h[k] = {comment: :description, department_id: :team_id}[k] || k
        h
      end
      converters = options.delete(:converters) || {}
      default_values = options[:default_values] || {}
      options[:rename].each do |old_column, new_column|
        raise "What is #{old_column}? #{columns.keys.sort.to_sentence} only are accepted." unless columns.keys.include?(old_column)
        renamings[old_column] = new_column
      end if options[:rename]
      model = options[:model] || backup_model
      klass = model.to_s.camelcase.constantize
      browse_and_match(backup_model) do |item|
        # puts item.inspect.magenta
        finder = keys.inject({}) do |hash, key|
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
        # puts attributes.inspect
        record.attributes = attributes
        record.save!
        record.id
      end
    end

    def browse_and_match(backup_model, &block)
      @matchings[backup_model] ||= {}
      self[backup_model].each do |item|
        @matchings[backup_model][item.id] = yield(item)
      end
    end

  end



  # Unzip file
  dir = w.tmp_dir
  Zip::File.open(file) do |zile|
    zile.each do |entry|
      entry.extract(dir.join(entry.name))
    end
  end

  database = dir.join("backup.xml")
  if database.exist?
    # CAUTION Fixed manually by counting points
    w.count = 16
    f = File.open(database)
    doc = Nokogiri::XML(f) do |config|
      config.strict.nonet.noblanks.noent
    end
    f.close

    root = doc.root
    if root.attr(:version).to_s == "20120806083148" # Ekylibre v0.4
      data = Backup.load(root.children.first)
      # :accounts, :cultivations, :custom_fields, :delays, :districts, :document_templates, :entity_categories, :entity_link_natures, :entity_natures, :establishments, :event_natures, :incoming_delivery_modes, :journals, :land_parcel_groups, :listings, :operation_natures, :outgoing_delivery_modes, :production_chains, :professions, :roles, :sequences, :tools, :units

      delays = data[:delay].inject({}) do |hash, item|
        hash[item.id] = item.expression
        hash
      end
      w.check_point

      # Import accounts
      chart_of_accounts = Preference[:chart_of_accounts]
      data.browse_and_match(:account) do |item|
        unless account = Account.find_by(number: item.number)
          reference = Nomen::Accounts.list.detect do |ref|
            ref.send(chart_of_accounts).to_s == item.number
          end
          account = Account.create!(number: item.number, name: item.name, last_letter: item.last_letter, debtor: item.is_debit, reconcilable: item.reconcilable, usages: (reference ? reference.name : nil))
        end
        account.id
      end
      w.check_point

      # Import financial_years
      data.import(:financial_year, :code, rename: {last_journal_entry_id: nil})
      w.check_point
      data.import(:establishment, :nic, rename: {nic: :code, siret: nil})
      w.check_point
      data.import(:department, :name, model: :team)
      w.check_point
      data.import(:district, :name, :code)
      w.check_point
      data.import(:journal, :name, converters: {
                    nature: lambda{ |j| j.nature == "renew" ? "forward" : j.nature }
                  })
      w.check_point
      data.import(:sequence, :number_format)
      w.check_point
      data.import(:role, :name, rename: {rights: nil})
      w.check_point
      data[:user].each do |item|
        item.email = item.name + "@ekylibre.org" if item.email.blank?
      end
      password = "12345678"
      data.import(:user, :email, rename: {admin: :administrator, office: nil, profession_id: nil, arrived_on: nil, departed_on: nil, hashed_password: nil, salt: nil, reduction_percent: :maximal_grantable_reduction_percentage, connected_at: :last_sign_in_at, name: nil, rights: nil}, default_values: {password: password, password_confirmation: password})
      w.check_point
      data.import(:entity, :code, rename: {code: :number, category_id: nil, nature_id: nil, payment_delay_id: nil, payment_mode_id: nil, webpass: nil, vat_submissive: :vat_subjected, soundex: nil, salt: nil, hashed_password: nil, invoices_count: nil, origin: :meeting_origin, attorney: nil, attorney_account_id: nil, born_on: :born_at, dead_on: :dead_at, discount_rate: nil, reduction_rate: nil, reflation_submissive: :reminder_submissive, ean13: nil, excise: nil, first_met_on: :first_met_at, website: nil, photo: nil}, default_values: {nature: "legal_entity", type: "Entity"})
      w.check_point
      data.import(:cash, :name, rename: {iban_label: :spaced_iban, address: :bank_agency_address, agency_code: :bank_agency_code, bic: :bank_identifier_code, by_default: nil, entity_id: :owner_id, key: :bank_account_key, number: :bank_account_number})
      w.check_point
      data.import(:bank_statement, :cash_id, :number, rename: {started_on: :started_at, stopped_on: :stopped_at})
      w.check_point
      data.import(:custom_field, :name, rename: {decimal_max: :maximal_value, decimal_min: :minimal_value, length_max: :maximal_length}, default_values: {customized_type: 'Entity'})
      w.check_point
      data.import(:journal_entry, :journal_id, :number, rename: {original_debit: :real_debit, original_credit: :real_credit, original_currency: :real_currency, original_currency_rate: :real_currency_rate, created_on: nil})
      w.check_point
      data.import(:journal_entry_line, :entry_id, :position, rename: {original_debit: :real_debit, original_credit: :real_credit}, model: :journal_entry_item)
      w.check_point

      # puts (data.keys - data.matchings.keys).inspect.red
    else
      raise NotSupportedFormatError
    end
  else
    raise NotWellFormedFileError
  end


end
