# encoding: UTF-8

# TODO: I18nize seeds !!!
language = 'fra'
currency = 'EUR'
user = {}
user[:first_name] = ENV["first_name"] || "Admin"
user[:last_name] = ENV["last_name"] || "STRATOR"
unless user[:email] = ENV["email"]
  user[:email] = "admin@ekylibre.org"
  puts "Username is: #{user[:email]}"
end
unless user[:password] = ENV["password"]
  user[:password] = User.give_password(8, :normal)
  puts "Password is: #{user[:password]}"
end
user[:password_confirmation] = user[:password]
user = User.new(user)

company = ENV["company"] || "My Company"

ActiveRecord::Base.transaction do
  Sequence.load_defaults
  Unit.load_defaults

  EntityNature.create!(:name => 'Monsieur', :title => 'M', :gender => :man)
  EntityNature.create!(:name => 'Madame', :title => 'Mme', :gender => :woman)
  EntityNature.create!(:name => 'Société Anonyme', :title => 'SA', :gender => :organization)
  undefined_nature = EntityNature.create!(:name => 'Indéfini', :title => '', :in_name => false, :gender => :undefined)
  category = EntityCategory.create!(:name => I18n.t('models.company.default.category'))
  firm = Entity.create!(:category_id =>  category.id, :nature_id => undefined_nature.id, :language => language, :last_name => company, :currency => currency, :of_company => true)
  firm.addresses.create!(:canal => "mail", :mail_line_2 => "", :mail_line_3 => "", :mail_line_4 => "", :mail_line_5 => "", :mail_line_6 => "", :by_default => true)

  user.administrator = true
  user.role = Role.create!(:name => I18n.t('models.company.default.role.name.administrator'), :rights => User.rights_list.join(' '))
  Role.create!(:name => I18n.t('models.company.default.role.name.public'), :rights => '')
  user.save!

  Account.load_chart(:accounting_system)

  Department.create!(:name => I18n.t('models.company.default.department_name'))
  establishment = Establishment.create!(:name => I18n.t('models.company.default.establishment_name'))
  # currency = company.currency || 'EUR' # company.currencies.create!(:name => 'Euro', :code => 'EUR', :value_format => '%f €', :rate => 1)

  for code, tax in I18n.t("models.company.default.taxes")
    Tax.create!(:name => tax[:name], :nature => (tax[:nature]||Tax.nature.default_value), :amount => tax[:amount].to_f, :collected_account_id => Account.get(tax[:collected], tax[:name]).id, :paid_account_id => Account.get(tax[:paid], tax[:name]).id)
  end

  # loading of all the templates
  DocumentTemplate.load_defaults

  journals = {}
  for journal in Journal.nature.values
    j = Journal.create!(:name => I18n.t("enumerize.journal.nature.#{journal}"), :nature => journal.to_s, :currency => currency)
    # company.prefer!("#{journal}_journal", j)
    journals[journal.to_sym] = j
    # company.prefer!("#{journal}_journal", company.journals.create!(:name => I18n.t("models.company.default.journals.#{journal}"), :nature => journal.to_s, :currency => currency))
  end

  cash = Cash.create!(:name => I18n.t('enumerize.cash.nature.cash_box'), :nature => "cash_box", :account => Account.get("531101", "Caisse"), :journal_id => journals[:cash].id)
  baac = Cash.create!(:name => I18n.t('enumerize.cash.nature.bank_account'), :nature => "bank_account", :account => Account.get("512101", "Compte bancaire"), :journal_id => journals[:bank].id, :iban => "FR7611111222223333333333391", :mode => "iban")

  IncomingPaymentMode.create!(:name => I18n.t('models.company.default.incoming_payment_modes.cash.name'), :cash_id => cash.id, :with_accounting => true, :attorney_journal => journals[:various])
  IncomingPaymentMode.create!(:name => I18n.t('models.company.default.incoming_payment_modes.check.name'), :cash_id => baac.id, :with_accounting => true, :with_deposit => true, :depositables_account_id => Account.get("5112", "Chèques à encaisser").id, :depositables_journal_id => journals[:various].id, :attorney_journal => journals[:various])
  IncomingPaymentMode.create!(:name => I18n.t('models.company.default.incoming_payment_modes.transfer.name'), :cash_id => baac.id, :with_accounting => true, :attorney_journal => journals[:various])

  OutgoingPaymentMode.create!(:name => I18n.t('models.company.default.outgoing_payment_modes.cash.name'), :cash_id => cash.id, :with_accounting => true, :attorney_journal => journals[:various])
  OutgoingPaymentMode.create!(:name => I18n.t('models.company.default.outgoing_payment_modes.check.name'), :cash_id => baac.id, :with_accounting => true, :attorney_journal => journals[:various])
  OutgoingPaymentMode.create!(:name => I18n.t('models.company.default.outgoing_payment_modes.transfer.name'), :cash_id => baac.id, :with_accounting => true, :attorney_journal => journals[:various])

  FinancialYear.create!(:started_on => Date.today.beginning_of_month)
  #SaleNature.create!(:name => I18n.t('models.company.default.sale_nature_name'), :expiration_delay => "30 day", :payment_delay => "30 day", :downpayment => false, :downpayment_minimum => 300, :downpayment_percentage => 30, :currency => currency, :with_accounting => true, :journal => journals[:sales])
  PurchaseNature.create!(:name => I18n.t('models.company.default.purchase_nature_name'), :currency => currency, :with_accounting => true, :journal => journals[:purchases])


  # @TODO - create default products

  # Add custom_field data to test
end

