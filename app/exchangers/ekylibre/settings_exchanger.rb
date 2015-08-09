class Ekylibre::SettingsExchanger < ActiveExchanger::Base
  # Create or updates main settings of folder
  def import
    @manifest = YAML.load_file(file) || {}
    @manifest.deep_symbolize_keys!

    @manifest[:company] ||= {}
    @manifest[:net_services] ||= {}
    @manifest[:identifiers] ||= {}
    @manifest[:language] ||= ::I18n.default_locale

    # Manual count of check points
    # $ grep -rin check_point app/exchangers/ekylibre/settings_exchanger.rb | wc -l
    w.count = 21 - 1

    # Global preferences
    language = I18n.locale = @manifest[:language]
    currency = @manifest[:currency] || 'EUR'
    country  = @manifest[:country] || 'fr'
    host = @manifest[:host] || 'erp.example.com'
    sales_conditions = @manifest[:sales_conditions] || ''
    Preference.set!(:language, language)
    Preference.set!(:currency, currency)
    Preference.set!(:country, country)
    Preference.set!(:host, host)
    Preference.set!(:sales_conditions, sales_conditions)
    if srs = @manifest[:map_measure_srs]
      Preference.set!(:map_measure_srs, srs)
    elsif srid = @manifest[:map_measure_srid]
      Preference.set!(:map_measure_srs, Nomen::SpatialReferenceSystems.find_by(srid: srid.to_i).name)
    end
    Preference.set!(:demo, !!@manifest[:demo], :boolean)
    Preference.set!(:create_activities_from_telepac, !!@manifest[:create_activities_from_telepac], :boolean)
    ::I18n.locale = Preference[:language]

    w.check_point

    # Sequences
    Sequence.load_defaults if can_load?(:sequences)
    w.check_point

    # Company entity
    # f = nil
    # for format in %w(jpg jpeg png)
    #   if company_picture = first_run.path("alamano", "logo.#{format}") and company_picture.exist?
    #     f = File.open(company_picture)
    #     break
    #   end
    # end
    attributes = { language: language, currency: currency, nature: :organization, last_name: 'Ekylibre' }.merge(@manifest[:company].select { |k, _v| ![:addresses].include?(k) }).merge(of_company: true)
    company = Entity.create!(attributes)
    # f.close if f
    if @manifest[:company][:addresses].is_a?(Hash)
      for address, value in @manifest[:company][:addresses]
        if value.is_a?(Hash)
          value[:canal] ||= address
          for index in (1..6).to_a
            value["mail_line_#{index}"] = value.delete("line_#{index}".to_sym)
          end
          company.addresses.create!(value)
        else
          company.addresses.create!(canal: address, coordinate: value)
        end
      end
    end
    w.check_point

    # Teams
    if can_load_default?(:teams)
      @manifest[:teams] = { default: { name: Team.tc('default') } }
    end
    create_records(:teams)
    w.check_point

    # Roles
    if can_load_default?(:roles)
      @manifest[:roles] = {
        default: { name: Role.tc('default.public') },
        administrator: { name: Role.tc('default.administrator'), rights: Ekylibre::Access.all_rights }
      }
    end
    create_records(:roles)
    w.check_point

    # Users
    if can_load_default?(:users)
      @manifest[:users] = { 'admin@ekylibre.org' => { first_name: 'Admin', last_name: 'EKYLIBRE' } }
    end
    for email, attributes in @manifest[:users]
      attributes[:administrator] = true unless attributes.key?(:administrator)
      attributes[:language] ||= language
      for ref in [:role, :team]
        attributes[ref] ||= :default
        attributes[ref] = get_record(ref.to_s.pluralize, attributes[ref])
      end
      unless attributes[:password]
        if Rails.env.development?
          attributes[:password] = '12345678'
        else
          attributes[:password] = User.give_password(8, :normal)
          unless Rails.env.test?
            w.notice "New password for account #{attributes[:email]}: #{attributes[:password]}"
          end
        end
      end
      attributes[:password_confirmation] = attributes[:password]
      user = User.find_or_initialize_by(email: email.to_s)
      user.attributes = attributes
      user.save!
    end
    w.check_point

    # Catalogs
    create_records(:catalogs, :code)
    w.check_point

    # Load chart of account
    if chart = @manifest[:chart_of_accounts] || @manifest[:chart_of_account]
      Account.chart = chart
      Account.load_defaults
    end
    w.check_point

    # Load accounts
    if can_load_default?(:accounts)
      @manifest[:accounts] = Cash.nature.values.inject({}) do |hash, nature|
        hash[nature] = { name: "enumerize.cash.nature.#{nature}".t,
                         number: sprintf('%08d', rand(10**7)) }
        hash
      end
    end
    create_records(:accounts)

    w.check_point

    # Load financial_years
    create_records(:financial_years, :code)
    w.check_point

    # Load taxes from nomenclatures
    Tax.import_all_from_nomenclature(country.to_sym) if can_load?(:taxes)
    w.check_point

    # Load all the document templates
    DocumentTemplate.load_defaults if can_load?(:document_templates)
    w.check_point

    # Loads journals
    if can_load_default?(:journals)
      @manifest[:journals] = Journal.nature.values.inject({}) do |hash, nature|
        hash[nature] = { name: "enumerize.journal.nature.#{nature}".t, nature: nature.to_s, currency: currency, closed_on: Date.new(1899, 12, 31).end_of_month }
        hash
      end
    end
    create_records(:journals, :code)
    w.check_point

    # Load cashes
    if can_load_default?(:cashes)
      @manifest[:cashes] = [:bank_account, :cash_box].inject({}) do |hash, nature|
        unless journal_nature = { bank_account: :bank, cash_box: :cash }[nature]
          fail StandardError, 'Need a valid journal nature to register a cash'
        end
        journal = Journal.find_by(nature: journal_nature)
        account = Account.find_by(name: "enumerize.cash.nature.#{nature}".t)
        hash[nature] = { name: "enumerize.cash.nature.#{nature}".t, nature: nature.to_s,
                         account: account, journal: journal }
        # hash[nature].merge!(iban: 'FR7611111222223333333333391') if nature == :bank_account
        hash
      end
    end
    create_records(:cashes)
    w.check_point

    # Load incoming payment modes
    if can_load_default?(:incoming_payment_modes)
      @manifest[:incoming_payment_modes] = %w(cash check transfer).inject({}) do |hash, nature|
        if cash = Cash.find_by(nature: Cash.nature.values.include?(nature) ? nature : :bank_account)
          hash[nature] = { name: IncomingPaymentMode.tc("default.#{nature}.name"), with_accounting: true, cash: cash, with_deposit: (nature == 'check' ? true : false) }
          if hash[nature][:with_deposit] && journal = Journal.find_by(nature: 'bank')
            hash[nature][:depositables_journal] = journal
            hash[nature][:depositables_account] = Account.find_or_create_in_chart(:pending_deposit_payments)
          else
            hash[nature][:with_deposit] = false
          end
        end
        hash
      end
    end
    create_records(:incoming_payment_modes)
    w.check_point

    # Load outgoing payment modes
    if can_load_default?(:outgoing_payment_modes)
      @manifest[:outgoing_payment_modes] = %w(cash check transfer).inject({}) do |hash, nature|
        hash[nature] = { name: OutgoingPaymentMode.tc("default.#{nature}.name"),
                         with_accounting: true,
                         cash: Cash.find_by(nature:
                                              Cash.nature.values.include?(nature) ? nature : :bank_account) }
        hash
      end
    end
    create_records(:outgoing_payment_modes)
    w.check_point

    # Load sale natures
    if can_load_default?(:sale_natures)
      nature = :sales
      usage = :sale
      journal = Journal.find_by(nature: nature, currency: currency) || Journal.create!(name: "enumerize.journal.nature.#{nature}".t, nature: nature.to_s, currency: currency, closed_on: Date.new(1899, 12, 31).end_of_month)
      catalog = Catalog.of_usage(:sale).first || Catalog.create!(name: "enumerize.catalog.usage.#{usage}".t, usage: usage, currency: currency)
      @manifest[:sale_natures] = { default: { name: SaleNature.tc('default.name'), active: true, expiration_delay: '30 day', payment_delay: '30 day', downpayment: false, downpayment_minimum: 300, downpayment_percentage: 30, currency: currency, with_accounting: true, journal: journal, catalog: catalog } }
    end
    create_records(:sale_natures)
    w.check_point

    # Load purchase natures
    if can_load_default?(:purchase_natures)
      nature = :purchases
      journal = Journal.find_by(nature: nature, currency: currency) || Journal.create!(name: "enumerize.journal.nature.#{nature}".t, nature: nature.to_s, currency: currency, closed_on: Date.new(1899, 12, 31).end_of_month)
      @manifest[:purchase_natures] = { default: { name: PurchaseNature.tc('default.name'), active: true, currency: currency, with_accounting: true, journal: journal } }
    end
    create_records(:purchase_natures)
    w.check_point

    # Load net services
    for name, identifiers in @manifest[:net_services]
      net_service = NetService.create!(reference_name: name)
      for nature, value in identifiers
        net_service.identifiers.create!(nature: nature, value: value)
      end
    end
    w.check_point

    # Load identifiers
    for nature, value in @manifest[:identifiers]
      Identifier.create!(nature: nature, value: value)
    end
    w.check_point
  end

  protected

  def can_load?(key)
    !@manifest[key].is_a?(FalseClass)
  end

  def can_load_default?(key)
    can_load?(key) && !@manifest[key].is_a?(Hash)
  end

  def create_records(records, *args)
    options = args.extract_options!
    main_column = args.shift || :name
    model = records.to_s.classify.constantize
    if data = @manifest[records]
      @records ||= {}.with_indifferent_access
      @records[records] ||= {}.with_indifferent_access
      unless data.is_a?(Hash)
        fail "Cannot load #{records}: Hash expected, got #{records.class.name} (#{records.inspect})"
      end
      for identifier, attributes in data
        attributes = attributes.with_indifferent_access
        attributes[main_column] ||= identifier.to_s
        for reflection in model.reflect_on_all_associations
          if attributes[reflection.name] and not attributes[reflection.name].class < ActiveRecord::Base
            attributes[reflection.name] = get_record(reflection.class_name.tableize, attributes[reflection.name].to_s)
          end
        end
        record = model.new(attributes)
        if record.save(attributes)
          @records[records][identifier.to_s] = record
        else
          puts "\nError on #{record.inspect.red}: #{record.errors.full_messages.to_sentence}"
          fail ActiveRecord::RecordInvalid, record
        end
      end
    end
  end

  # Returns the record corresponding to the identifier
  def get_record(records, identifier)
    @records ||= {}.with_indifferent_access
    return @records[records][identifier] if @records[records]
    nil
  end
end
