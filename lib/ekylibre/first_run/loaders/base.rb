# -*- coding: utf-8 -*-
Ekylibre::FirstRun.add_loader :base do |first_run|

  # Global preferences
  language = I18n.locale = first_run.manifest[:language] || I18n.default_locale
  currency = first_run.manifest[:currency] || 'EUR'
  country  = first_run.manifest[:country]  || 'fr'
  Preference.get(:language).set!(language)
  Preference.get(:currency).set!(currency)
  Preference.get(:country).set!(country)
  if srid = first_run.manifest[:map_measure_srid]
    Preference.get(:map_measure_srid).set!(srid.to_i)
  end

  # Sequences
  if first_run.can_load?(:sequences)
    Sequence.load_defaults
  end

  # Company entity
  f = nil
  for format in %w(jpg jpeg png)
    if company_picture = first_run.path("alamano", "logo.#{format}") and company_picture.exist?
      f = File.open(company_picture)
      break
    end
  end
  attributes = {language: language, currency: currency, nature: "company", last_name: "Ekylibre"}.merge(first_run.manifest[:company].select{|k,v| ![:addresses].include?(k) }).merge(of_company: true, picture: f)
  company = LegalEntity.create!(attributes)
  f.close if f
  if first_run.manifest[:company][:addresses].is_a?(Hash)
    for address, value in first_run.manifest[:company][:addresses]
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
  if first_run.can_load_default?(:teams)
    first_run.manifest[:teams] = {default: {name: 'models.team.default'.t}}
  end
  first_run.create_from_manifest(:teams)

  # Establishment
  if first_run.can_load_default?(:establishments)
    first_run.manifest[:establishments] = {default: {name: 'models.establishment.default'.t}}
  end
  first_run.create_from_manifest(:establishments)

  # Roles
  if first_run.can_load_default?(:roles)
    first_run.manifest[:roles] = {
      default: {name: 'models.role.default.public'.t},
      administrator: {name: 'models.role.default.administrator'.t, rights: Ekylibre::Access.actions}
    }
  end
  first_run.create_from_manifest(:roles)

  # Users
  if first_run.can_load_default?(:users)
    first_run.manifest[:users] = {"admin@ekylibre.org" => {first_name: "Admin", last_name: "EKYLIBRE"}}
  end
  for email, attributes in first_run.manifest[:users]
    attributes[:email] = email.to_s
    attributes[:administrator] = true unless attributes.has_key?(:administrator)
    attributes[:language] ||= language
    for ref in [:role, :team, :establishment]
      attributes[ref] ||= :default
      attributes[ref] = first_run.get(ref.to_s.pluralize, attributes[ref])
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
    User.create!(attributes)
  end

  # Catalogs
  first_run.create_from_manifest(:catalogs, :code)

  # Load chart of account
  if first_run.manifest[:chart_of_account]
    Account.chart = first_run.manifest[:chart_of_account]
    Account.load
  end

  # Load accounts
  first_run.create_from_manifest(:accounts)

  # Load financial_years
  first_run.create_from_manifest(:financial_years, :code)

  # Load taxes from nomenclatures
  if first_run.can_load?(:taxes)
    Tax.import_all_from_nomenclature(country.to_sym)
  end

  # Load all the document templates
  if first_run.can_load?(:document_templates)
    DocumentTemplate.load_defaults
  end

  # Loads journals
  if first_run.can_load_default?(:journals)
    first_run.manifest[:journals] = Journal.nature.values.inject({}) do |hash, nature|
      hash[nature] = {name: "enumerize.journal.nature.#{nature}".t, nature: nature.to_s, currency: currency, closed_at: Time.new(1899, 12, 31).end_of_month}
      hash
    end
  end
  first_run.create_from_manifest(:journals)

  # Load cashes
  first_run.create_from_manifest(:cashes)

  # Load incoming payment modes
  if first_run.can_load_default?(:incoming_payment_modes)
    first_run.manifest[:incoming_payment_modes] = %w(cash check transfer).inject({}) do |hash, nature|
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
  first_run.create_from_manifest(:incoming_payment_modes)

  # Load outgoing payment modes
  if first_run.can_load_default?(:outgoing_payment_modes)
    first_run.manifest[:outgoing_payment_modes] = %w(cash check transfer).inject({}) do |hash, nature|
      hash[nature] = {name: "models.outgoing_payment_mode.default.#{nature}.name".t, with_accounting: true, cash: Cash.find_by(nature: Cash.nature.values.include?(nature) ? nature : :bank_account)}
      hash
    end
  end
  first_run.create_from_manifest(:outgoing_payment_modes)

  # Load sale natures
  if first_run.can_load_default?(:sale_natures)
    first_run.manifest[:sale_natures] = {default: {name: 'models.sale_nature.default.name'.t, active: true, expiration_delay: "30 day", payment_delay: "30 day", downpayment: false, downpayment_minimum: 300, downpayment_percentage: 30, currency: currency, with_accounting: true, journal: :sales, catalog: Catalog.of_usage(:sale).first}}
  end
  first_run.create_from_manifest(:sale_natures)

  # Load purchase natures
  if first_run.can_load_default?(:purchase_natures)
    first_run.manifest[:sale_natures] = {default: {name: "models.purchase_nature.default.name".t, active: true, currency: currency, with_accounting: true, journal: :purchases}}
  end
  first_run.create_from_manifest(:purchase_natures)

  # Load net services
  for name, identifiers in first_run.manifest[:net_services]
    service = NetService.create!(reference_name: name)
    for nature, value in identifiers
      service.identifiers.create!(nature: nature, value: value)
    end
  end

  # Load identifiers
  for nature, value in first_run.manifest[:identifiers]
    Identifier.create!(nature: nature, value: value)
  end

end
