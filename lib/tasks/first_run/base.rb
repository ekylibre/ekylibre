# -*- coding: utf-8 -*-
load_data :base do |loader|

  # Global preferences
  language = I18n.locale = loader.manifest[:language] || I18n.default_locale
  currency = loader.manifest[:currency] || 'EUR'
  country  = loader.manifest[:country]  || 'fr'
  Preference.get(:language).set!(language)
  Preference.get(:currency).set!(currency)
  Preference.get(:country).set!(country)
  if srid = loader.manifest[:map_measure_srid]
    Preference.get(:map_measure_srid).set!(srid.to_i)
  end

  # Sequences
  if loader.can_load?(:sequences)
    Sequence.load_defaults
  end

  # Company entity
  f = nil
  for format in %w(jpg jpeg png)
    if company_picture = loader.path("alamano", "logo.#{format}") and company_picture.exist?
      f = File.open(company_picture)
      break
    end
  end
  attributes = {language: language, currency: currency, nature: "company", last_name: "Ekylibre"}.merge(loader.manifest[:company].select{|k,v| ![:addresses].include?(k) }).merge(of_company: true, picture: f)
  company = LegalEntity.create!(attributes)
  f.close if f
  if loader.manifest[:company][:addresses].is_a?(Hash)
    for address, value in loader.manifest[:company][:addresses]
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

  # Teams
  if loader.can_load_default?(:teams)
    loader.manifest[:teams] = {default: {name: 'models.team.default'.t}}
  end
  loader.create_from_manifest(:teams)

  # Establishment
  if loader.can_load_default?(:establishments)
    loader.manifest[:establishments] = {default: {name: 'models.establishment.default'.t}}
  end
  loader.create_from_manifest(:establishments)

  # Roles
  if loader.can_load_default?(:roles)
    loader.manifest[:roles] = {
      default: {name: 'models.role.default.public'.t},
      administrator: {name: 'models.role.default.administrator'.t, rights: Ekylibre::Access.actions}
    }
  end
  loader.create_from_manifest(:roles)

  # Users
  if loader.can_load_default?(:users)
    loader.manifest[:users] = {"admin@ekylibre.org" => {first_name: "Admin", last_name: "EKYLIBRE"}}
  end
  for email, attributes in loader.manifest[:users]
    attributes[:email] = email.to_s
    attributes[:administrator] = true unless attributes.has_key?(:administrator)
    attributes[:language] ||= language
    for ref in [:role, :team, :establishment]
      attributes[ref] ||= :default
      attributes[ref] = loader.get(ref.to_s.pluralize, attributes[ref])
    end
    unless attributes[:password]
      if Rails.env.development?
        attributes[:password] = "12345678"
      else
        attributes[:password] = User.give_password(8, :normal)
        puts "New password for account #{attributes[:email]}: #{attributes[:password]}"
      end
    end
    attributes[:password_confirmation] = attributes[:password]
    for format in %w(jpg jpeg png)
      if path = loader.path("alamano", "entities_pictures", "#{attributes[:email]}.#{format}") and path.exist?
        attributes[:picture] = File.open(path)
        break
      end
    end
    User.create!(attributes)
  end

  # Catalogs
  loader.create_from_manifest(:catalogs, :code)

  # Load chart of account
  if loader.manifest[:chart_of_account]
    Account.chart = loader.manifest[:chart_of_account]
    Account.load
  end

  # Load accounts
  loader.create_from_manifest(:accounts)

  # Load financial_years
  loader.create_from_manifest(:financial_years, :code)

  # Load taxes from nomenclatures
  if loader.can_load?(:taxes)
    Tax.import_all_from_nomenclature(country.to_sym)
  end

  # Load all the document templates
  if loader.can_load?(:document_templates)
    DocumentTemplate.load_defaults
  end

  # Loads journals
  if loader.can_load_default?(:journals)
    loader.manifest[:journals] = Journal.nature.values.inject({}) do |hash, nature|
      hash[nature] = {name: "enumerize.journal.nature.#{nature}".t, nature: nature.to_s, currency: currency, closed_at: Time.new(1899, 12, 31).end_of_month}
      hash
    end
  end
  loader.create_from_manifest(:journals)

  # Load cashes
  loader.create_from_manifest(:cashes)

  # Load incoming payment modes
  if loader.can_load_default?(:incoming_payment_modes)
    loader.manifest[:incoming_payment_modes] = %w(cash check transfer).inject({}) do |hash, nature|
      hash[nature] = {name: "models.incoming_payment_mode.default.#{nature}.name".t, with_accounting: true, cash: Cash.find_by(nature: Cash.nature.values.include?(nature) ? nature : :bank_account), with_deposit: (nature == "check" ? true : false)}
      if hash[nature][:with_deposit] and journal = Journal.find_by(nature: "bank")
        hash[nature][:depositables_journal] = journal
        hash[nature][:depositables_account] = Account.find_or_create_in_chart(:pending_deposit_payments)
      else
        hash[nature][:with_deposit] = false
      end
      hash
    end
  end
  loader.create_from_manifest(:incoming_payment_modes)

  # Load outgoing payment modes
  if loader.can_load_default?(:outgoing_payment_modes)
    loader.manifest[:outgoing_payment_modes] = %w(cash check transfer).inject({}) do |hash, nature|
      hash[nature] = {name: "models.outgoing_payment_mode.default.#{nature}.name".t, with_accounting: true, cash: Cash.find_by(nature: Cash.nature.values.include?(nature) ? nature : :bank_account)}
      hash
    end
  end
  loader.create_from_manifest(:outgoing_payment_modes)

  # Load sale natures
  if loader.can_load_default?(:sale_natures)
    loader.manifest[:sale_natures] = {default: {name: 'models.sale_nature.default.name'.t, active: true, expiration_delay: "30 day", payment_delay: "30 day", downpayment: false, downpayment_minimum: 300, downpayment_percentage: 30, currency: currency, with_accounting: true, journal: :sales, catalog: Catalog.of_usage(:sale).first}}
  end
  loader.create_from_manifest(:sale_natures)

  # Load purchase natures
  if loader.can_load_default?(:purchase_natures)
    loader.manifest[:sale_natures] = {default: {name: "models.purchase_nature.default.name".t, active: true, currency: currency, with_accounting: true, journal: :purchases}}
  end
  loader.create_from_manifest(:purchase_natures)

  # Load net services
  for name, identifiers in loader.manifest[:net_services]
    service = NetService.create!(reference_name: name)
    for nature, value in identifiers
      service.identifiers.create!(nature: nature, value: value)
    end
  end

  # Load identifiers
  for nature, value in loader.manifest[:identifiers]
    Identifier.create!(nature: nature, value: value)
  end

end
