# encoding: UTF-8

# TODO: I18nize seeds !!!
I18n.locale = ENV["locale"] || "fra"
language = I18n.locale
currency = 'EUR'
user = {}
user[:first_name] = ENV["first_name"] || "Jean"
user[:last_name] = ENV["last_name"] || "DUPONT"
unless user[:email] = ENV["email"]
  user[:email] = "admin@ekylibre.org"
  puts "Username is: #{user[:email]}"
end
unless user[:password] = ENV["password"]
  user[:password] = (Rails.env.development? ? "12345678" : User.give_password(8, :normal))
  puts "Password is: #{user[:password]}"
end
user[:password_confirmation] = user[:password]
user[:employed] = true
user = User.new(user)

company = ENV["company"] || "GAEC DUPONT"

ActiveRecord::Base.transaction do
  Sequence.load_defaults
  Unit.load_defaults
  EntityNature.load_defaults
  undefined_nature = EntityNature.where(:gender => "undefined").first
  sale_price_listing = ProductPriceListing.create!(:name => I18n.t('models.product_price_listing.default.name'))
  firm = Entity.create!(:sale_price_listing_id => sale_price_listing.id, :nature_id => undefined_nature.id, :language => language, :last_name => company, :currency => currency, :of_company => true)
  firm.addresses.create!(:canal => "mail", :mail_line_2 => "", :mail_line_3 => "", :mail_line_4 => "", :mail_line_5 => "", :mail_line_6 => "", :by_default => true)

  user.administrator = true
  user.role = Role.create!(:name => I18n.t('models.company.default.role.name.administrator'), :rights => User.rights_list.join(' '))
  Role.create!(:name => I18n.t('models.company.default.role.name.public'), :rights => '')
  user.save!

  Account.load_chart(:accounting_system)

  Department.create!(:name => I18n.t('models.company.default.department_name'))
  establishment = Establishment.create!(:name => I18n.t('models.company.default.establishment_name'))
  # currency = company.currency || 'EUR' # company.currencies.create!(:name => 'Euro', :code => 'EUR', :value_format => '%f €', :rate => 1)

  for code, tax in I18n.t("models.tax.default")
    Tax.create!(:name => tax[:name], :nature => (tax[:nature]||Tax.nature.default_value), :amount => tax[:amount].to_f, :collected_account_id => Account.get(tax[:collected], tax[:name]).id, :paid_account_id => Account.get(tax[:paid], tax[:name]).id)
  end

  # Load all the document templates
  DocumentTemplate.load_defaults

  journals = {}
  for journal in Journal.nature.values
    j = Journal.create!(:name => I18n.t("enumerize.journal.nature.#{journal}"), :nature => journal.to_s, :currency => currency)
    # company.prefer!("#{journal}_journal", j)
    journals[journal.to_sym] = j
    # company.prefer!("#{journal}_journal", company.journals.create!(:name => I18n.t("models.company.default.journals.#{journal}"), :nature => journal.to_s, :currency => currency))
  end

  cash = Cash.create!(:name => I18n.t('enumerize.cash.nature.cash_box'), :nature => "cash_box", :account_id => Account.get("531101", "Caisse").id, :journal_id => journals[:cash].id)
  baac = Cash.create!(:name => I18n.t('enumerize.cash.nature.bank_account'), :nature => "bank_account", :account_id => Account.get("512101", "Compte bancaire").id, :journal_id => journals[:bank].id, :iban => "FR7611111222223333333333391", :mode => "iban")

  IncomingPaymentMode.create!(:name => I18n.t('models.incoming_payment_mode.default.cash.name'), :cash_id => cash.id, :with_accounting => true, :attorney_journal_id => journals[:various].id)
  IncomingPaymentMode.create!(:name => I18n.t('models.incoming_payment_mode.default.check.name'), :cash_id => baac.id, :with_accounting => true, :with_deposit => true, :depositables_account_id => Account.get("5112", "Chèques à encaisser").id, :depositables_journal_id => journals[:various].id, :attorney_journal_id => journals[:various].id)
  IncomingPaymentMode.create!(:name => I18n.t('models.incoming_payment_mode.default.transfer.name'), :cash_id => baac.id, :with_accounting => true, :attorney_journal_id => journals[:various].id)

  OutgoingPaymentMode.create!(:name => I18n.t('models.outgoing_payment_mode.default.cash.name'), :cash_id => cash.id, :with_accounting => true, :attorney_journal_id => journals[:various].id)
  OutgoingPaymentMode.create!(:name => I18n.t('models.outgoing_payment_mode.default.check.name'), :cash_id => baac.id, :with_accounting => true, :attorney_journal_id => journals[:various].id)
  OutgoingPaymentMode.create!(:name => I18n.t('models.outgoing_payment_mode.default.transfer.name'), :cash_id => baac.id, :with_accounting => true, :attorney_journal_id => journals[:various].id)

  FinancialYear.create!(:started_on => Date.today.beginning_of_month)

  SaleNature.create!(:name => I18n.t('models.sale_nature.default.name'), :active => true, :expiration_delay => "30 day", :payment_delay => "30 day", :downpayment => false, :downpayment_minimum => 300, :downpayment_percentage => 30, :currency => currency, :with_accounting => true, :journal_id => journals[:sales].id)
  PurchaseNature.create!(:name => I18n.t('models.purchase_nature.default.name'), :active => true, :currency => currency, :with_accounting => true, :journal_id => journals[:purchases].id)


  # @TODO - create default products

  # Add custom_field data to test
end

