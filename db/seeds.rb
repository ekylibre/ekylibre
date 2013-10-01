# encoding: UTF-8

# TODO: I18nize seeds !!!
I18n.locale = ENV["language"] || ENV["locale"] || 'fra'
language = I18n.locale
currency = ENV['currency'] || 'EUR'
country  = ENV['country']  || 'fr'
picture_company = Rails.root.join("app", "assets", "images", "ekylibre.png")
user = {}
user[:first_name] = ENV["first_name"] || "Jean"
user[:last_name]  = ENV["last_name"]  || "DUPONT"
unless user[:email] = ENV["email"]
  user[:email] = "admin@ekylibre.org"
  puts "Username: #{user[:email]}"
end
unless user[:password] = ENV["password"]
  user[:password] = (Rails.env.development? ? "12345678" : User.give_password(8, :normal))
  puts "Password: #{user[:password]}"
end
user[:password_confirmation] = user[:password]
user[:employed] = true
user = User.new(user)

company = ENV["company"] || "GAEC DUPONT"

ActiveRecord::Base.transaction do

  Preference.get(:language).set!(language)
  Preference.get(:currency).set!(currency)
  Preference.get(:country).set!(country)

  Sequence.load_defaults

  catalog = Catalog.create!(:name => I18n.t('models.catalog.default.name'), :currency => currency, :usage => :sale)

  undefined_nature = "entity"
  f = File.open(picture_company)
  firm = LegalEntity.create!(:nature => "company", :language => language, :last_name => company, :currency => currency, :of_company => true, :picture => f)
  f.close
  firm.addresses.create!(:canal => :mail, :mail_line_4 => "8 rue du bouil bleu", :mail_line_6 => "17250 SAINT-PORCHAIRE", :mail_country => "fr", :by_default => true)

  user.administrator = true
  user.language = language
  user.role = Role.create!(:name => 'models.role.default.administrator'.t, :rights => User.rights_list.join(' '))
  Role.create!(:name => 'models.role.default.public'.t, :rights => '')
  user.save!

  Account.chart = ENV["chart"] || :fr_pcga

  Account.load

  Team.create!(:name => 'models.team.default'.t)

  Establishment.create!(:name => 'models.establishment.default'.t)

  # Load french tax from nomenclatures
  Tax.import_all_from_nomenclature(:fr)

  # Load all the document templates
  DocumentTemplate.load_defaults

  journals = {}
  for journal in Journal.nature.values
    j = Journal.create!(:name => I18n.t("enumerize.journal.nature.#{journal}"), :nature => journal.to_s, :currency => currency)
    journals[journal.to_sym] = j
  end

  cash = Cash.create!(:name => I18n.t('enumerize.cash.nature.cash_box'), :nature => "cash_box", :account_id => Account.get("531101", "Caisse").id, :journal_id => journals[:cash].id)
  baac = Cash.create!(:name => I18n.t('enumerize.cash.nature.bank_account'), :nature => "bank_account", :account_id => Account.get("51210000", "Compte bancaire").id, :journal_id => journals[:bank].id, :iban => "FR7611111222223333333333391", :mode => "iban")

  IncomingPaymentMode.create!(:name => I18n.t('models.incoming_payment_mode.default.cash.name'), :cash_id => cash.id, :with_accounting => true, :attorney_journal_id => journals[:various].id)
  IncomingPaymentMode.create!(:name => I18n.t('models.incoming_payment_mode.default.check.name'), :cash_id => baac.id, :with_accounting => true, :with_deposit => true, :depositables_account_id => Account.get("5112", "Chèques à encaisser").id, :depositables_journal_id => journals[:various].id, :attorney_journal_id => journals[:various].id)
  IncomingPaymentMode.create!(:name => I18n.t('models.incoming_payment_mode.default.transfer.name'), :cash_id => baac.id, :with_accounting => true, :attorney_journal_id => journals[:various].id)

  OutgoingPaymentMode.create!(:name => I18n.t('models.outgoing_payment_mode.default.cash.name'), :cash_id => cash.id, :with_accounting => true, :attorney_journal_id => journals[:various].id)
  OutgoingPaymentMode.create!(:name => I18n.t('models.outgoing_payment_mode.default.check.name'), :cash_id => baac.id, :with_accounting => true, :attorney_journal_id => journals[:various].id)
  OutgoingPaymentMode.create!(:name => I18n.t('models.outgoing_payment_mode.default.transfer.name'), :cash_id => baac.id, :with_accounting => true, :attorney_journal_id => journals[:various].id)

  FinancialYear.create!(:started_on => Date.today.beginning_of_month)

  SaleNature.create!(:name => I18n.t('models.sale_nature.default.name'), :active => true, :expiration_delay => "30 day", :payment_delay => "30 day", :downpayment => false, :downpayment_minimum => 300, :downpayment_percentage => 30, :currency => currency, :with_accounting => true, :journal_id => journals[:sales].id, catalog_id: catalog.id)
  PurchaseNature.create!(:name => I18n.t('models.purchase_nature.default.name'), :active => true, :currency => currency, :with_accounting => true, :journal_id => journals[:purchases].id)
end

