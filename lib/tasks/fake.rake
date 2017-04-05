module Ekylibre
  module Fake
    class Variant
      class << self
        def supplier_types
          @supplier_types ||= @list.map(&:supplier_type).uniq.sort
        end

        def load(env = 'default')
          @list = []
          puts "Load #{env} variants".red
          CSV.read(Pathname.new(__FILE__).dirname.join('fake', env + '.csv'), headers: true)
             .map { |row| add(row.to_hash.symbolize_keys) }
        end

        def find(name)
          @list.detect { |v| v.name == name.to_s }
        end

        def add(attributes)
          @list ||= []
          attributes[:cost] = attributes[:cost].to_f.to_d
          @list << new(attributes)
        end

        def saleables
          @list.select do |v|
            start = Date.today - ((v.sale_frequency * 365.25) * 0.05).to_i
            last_quantity = SaleItem.where(variant: v.id, sale: Sale.where(state: %i[order invoice], confirmed_at: start..Date.today)).sum(:quantity)
            v.saleable? && last_quantity < 0.8 * v.sale_default_quantity
          end
        end

        def purchaseables(supplier_type = nil)
          supplier_type ||= self.class.supplier_types.sample
          @list.select do |v|
            start = Date.today - ((v.sale_frequency * 365.25) * 0.05).to_i
            last_quantity = SaleItem.where(variant: v.id, sale: Sale.where(state: %i[order invoice], confirmed_at: start..Date.today)).sum(:quantity)
            v.purchaseable? && last_quantity < 0.8 * v.purchase_default_quantity
          end
        end
      end

      attr_reader :name, :cost, :supplier_type, :sale_default_quantity, :purchase_default_quantity,
                  :sale_frequency, :purchase_frequency

      def initialize(attributes = {})
        @name = attributes[:name] || attributes[:variant]
        @cost = attributes[:cost]
        @deliverable = attributes[:deliverable].present?
        @saleable = attributes[:sale].present?
        @purchaseable = attributes[:purchase].present?
        @sale_frequency = attributes[:sale_frequency].to_f
        @purchase_frequency = attributes[:purchase_frequency].to_f
        @sale_default_quantity = attributes[:sale_quantity].blank? ? 1 : attributes[:sale_quantity].to_d
        @purchase_default_quantity = attributes[:purchase_quantity].blank? ? 1 : attributes[:purchase_quantity].to_d
        @supplier_type = attributes[:purchase_quantity].blank? ? 1 : attributes[:purchase_quantity].to_d
      end

      delegate :id, to: :record

      def record
        ::I18n.locale = 'fra'
        ProductNatureVariant.import_from_nomenclature(@name)
      end

      def unit_pretax_amount
        (@cost * (1 + 0.07 * (rand - 0.5))).round(1)
      end

      def sale_quantity
        record.population_counting_unitary? ? 1 : (@sale_default_quantity * (1 + 0.07 * (rand - 0.5))).round
      end

      def purchase_quantity
        record.population_counting_unitary? ? 1 : (@purchase_default_quantity * (1 + 0.07 * (rand - 0.5))).round
      end

      def deliverable?
        @deliverable
      end

      def saleable?
        @saleable
      end

      def purchaseable?
        @purchaseable
      end
    end

    def self.run(options = {})
      Variant.load(options[:env])
      puts 'Gooooo!'.red
      Base.new(options).run
    end

    class Base
      attr_reader :on, :currency
      delegate :monday?, :tuesday?, :wenesday?, :thursday?, :friday?, :saturday?, :sunday?,
               :day, :month, :year, :mday, :wday, :strftime, to: :on

      def initialize(options = {})
        @currency = options[:currency] || 'EUR'
        @locale = options[:locale] || 'fra'
        @country = options[:locale] || 'fr'
        @started_on = options[:started_on] || Date.civil(2016, 8, 6)
        @stopped_on = options[:stopped_on] || Date.today
        @cash_minimum = options[:cash_minimun] || options[:cash_min] || -12_000
        @cash_maximum = options[:cash_maximun] || options[:cash_max] || @cash_minimum + 80_000
      end

      def bank_balance
        JournalEntryItem.where(account_id: Cash.select(:main_account_id)).sum('real_debit - real_credit')
      end

      def current_financial_year
        other = FinancialYear.at
        return other if other
        other = FinancialYear.where('stopped_on < ?', on).reorder(stopped_on: :desc).first
        other = other.find_or_create_next! while on > other.stopped_on if other
        other = FinancialYear.create!(started_on: on) unless other
        other
      end

      def find_or_create_user(options = {})
        if rand < 0.02
          u = User.where(locked: false).to_a.sample
          u.update_column(:locked, true) if u
        end
        user = if rand > 0.01 && User.where(options).any?
                 User.where(options).to_a.sample
               else
                 pass = FFaker::NameFR.first_name * 8
                 user = User.create!(
                   first_name: FFaker::NameFR.first_name,
                   last_name: FFaker::NameFR.last_name.mb_chars.upcase,
                   language: rand > 0.02 ? Preference[:language] : ::I18n.available_locales.sample,
                   administrator: true,
                   email: FFaker::Internet.safe_email,
                   password: pass,
                   password_confirmation: pass
                 )
               end
        user
      end

      def find_or_create_entity(options = {})
        options[:client] ||= (rand > 0.1)
        options[:supplier] ||= (rand > 0.9)
        options[:nature] ||= (rand > 0.7 ? :organization : :contact)
        entity = if rand < 0.3 && Entity.where(options).any?
                   Entity.where(options).to_a.sample
                 else
                   options[:creator] ||= User.where(locked: false).to_a.sample
                   if options[:nature] == :contact
                     options[:first_name] = FFaker::NameFR.first_name
                     options[:last_name] = FFaker::NameFR.last_name.mb_chars.upcase
                   else
                     options[:last_name] = FFaker::Company.name
                   end
                   Entity.find_or_create_by!(options)
                 end
        if rand > 0.4
          u = find_or_create_user(locked: false)
          entity.observations.create!(creator: u, author: u, content: FFaker::HipsterIpsum.words(15).join(' '))
        end

        # Adds
        if entity.mails.empty? #  && rand > 0.1
          entity.mails.create!(mail_line_4: FFaker::AddressFR.street_address, mail_line_6: FFaker::AddressFR.postal_code + ' ' + FFaker::AddressFR.city, mail_country: options[:country])
        end
        if entity.phones.empty? && rand > 0.7
          entity.phones.create!(coordinate: FFaker::PhoneNumberFR.home_work_phone_number)
        end
        if entity.mobiles.empty? && rand > 0.5
          entity.mobiles.create!(coordinate: FFaker::PhoneNumberFR.mobile_phone_number)
        end
        if entity.emails.empty? && rand > 0.6
          entity.emails.create!(coordinate: FFaker::Internet.safe_email)
        end
        entity
      end

      def find_or_create_building
        variant = ProductNatureVariant.import_from_nomenclature(:building)
        Building.create_with(born_at: Date.today - rand(6000).days, initial_population: 1)
                .find_or_create_by!(variant: variant)
      end

      def find_currency!(name)
        currency = Nomen::Currency.find(name || @currency)
        raise "What? #{name.inspect}" unless currency
        currency
      end

      def find_or_create_catalog(options = {})
        currency = find_currency!(options[:currency])
        usage = options[:usage] || :sale
        catalog = Catalog.find_by(usage: usage, currency: currency.name)
        unless catalog
          name = "enumerize.catalog.usage.#{usage}".t + ' 1'
          name.succ! while Catalog.find_by(name: name)
          code = name.codeize[0..3]
          code.succ! while Catalog.find_by(code: code)
          catalog = Catalog.create!(
            name: name,
            usage: usage,
            currency: currency.name,
            code: code
          )
        end
        catalog
      end

      def find_or_create_journal(options = {})
        currency = find_currency!(options[:currency])
        nature = options[:nature] || :various
        relation = Journal
        relation = options[:scope].call(relation) if options[:scope]
        journal = relation.find_by(currency: currency.name, nature: nature)
        unless journal
          name = options[:journal_name] || "enumerize.journal.nature.#{nature}".t + ' 1'
          code = name.codeize[0..1]
          code.succ! while Journal.find_by(code: code)
          journal = Journal.create!(
            currency: currency.name,
            name: name,
            code: code,
            nature: nature
          )
        end
        journal
      end

      def find_or_create_cash(options = {})
        currency = find_currency!(options[:currency])
        cash = Cash.find_by(nature: :bank_account, currency: currency.name)
        unless cash
          cash_name = options[:cash_name] || currency.human_name(locale: :eng) + ' Bank'
          account = options[:account] || Account.find_or_create_by_number('5120' + cash_name.codeize[0..7])
          journal = options[:journal] || find_or_create_journal(
            currency: currency.name,
            nature: :bank,
            scope: ->(r) { r.where.not(id: Cash.select(:journal_id)) },
            name: options[:journal_name],
            code: options[:journal_code]
          )
          cash = Cash.create!(
            name: cash_name,
            main_account: account,
            nature: :bank_account,
            journal: journal,
            currency: currency.name
          )
        end
        cash
      end

      def find_or_create_incoming_payment_mode(options = {})
        cash = options.delete(:cash) ||
               find_or_create_cash(options.slice(:cash_name, :currency, :journal, :account))
        IncomingPaymentMode.create_with(name: "#{cash.name} transfer").find_or_create_by!(
          cash: cash,
          with_accounting: true,
          active: true
        )
      end

      def find_or_create_outgoing_payment_mode(options = {})
        cash = options.delete(:cash) ||
               find_or_create_cash(options.slice(:cash_name, :currency, :journal, :account))
        OutgoingPaymentMode.create_with(name: "#{cash.name} transfer").find_or_create_by!(
          cash: cash,
          with_accounting: true,
          active: true
        )
      end

      def find_or_create_sale_nature(options = {})
        currency = find_currency!(options[:currency])
        nature = SaleNature.find_by(active: true, currency: currency.name, with_accounting: true)
        unless nature
          journal = find_or_create_journal(nature: :sales, currency: currency.name)
          catalog = find_or_create_catalog(usage: :sale, currency: currency.name)
          name = Sale.model_name.human + ' 1'
          name.succ! while SaleNature.find_by(name: name)
          nature = SaleNature.create!(
            name: name,
            active: true,
            currency: currency.name,
            with_accounting: true,
            catalog: catalog,
            journal: journal
          )
        end
        nature
      end

      def default_mail_address(entity, options = {})
        if entity.mails.empty?
          entity.mails.create!(mail_line_4: FFaker::AddressFR.street_address, mail_line_6: FFaker::AddressFR.postal_code + ' ' + FFaker::AddressFR.city, mail_country: options[:country] || Preference[:country], by_default: true)
          entity.reload
        end
        entity.default_mail_address
      end

      def set_storable(category)
        category.reload
        if category.depreciable
          category.fixed_asset_account ||= Account.find_or_create_by_number('21')
          category.fixed_asset_allocation_account ||= Account.find_or_create_by_number('26')
          category.fixed_asset_depreciation_method ||= :simplified_linear
          category.fixed_asset_depreciation_percentage ||= 5
          category.fixed_asset_expenses_account ||= Account.find_or_create_by_number('626')
        end
        category.storable = true
        category.stock_account ||= Account.find_or_create_by_number('31')
        category.stock_movement_account ||= Account.find_or_create_by_number('6031')
        category.save!
        category.variants.find_each(&:save!)
      end

      def create_sale(options = {})
        options[:nature] ||= find_or_create_sale_nature(options)
        sale = Sale.create!(options)
        variants = []
        (1 + rand(4)).times do
          next unless (variant = Variant.saleables.sample)
          next if variants.include? variant
          variants << variant
          sale.items.create!(
            compute_from: :unit_pretax_amount,
            unit_pretax_amount: variant.unit_pretax_amount,
            quantity: variant.sale_quantity,
            variant_id: variant.id,
            tax: Tax.where('amount >= ?', rand > 0.2 ? 19 : 0).to_a.sample
          )
        end
        unless sale.items.any?
          sale.destroy
          return nil
        end
        sale.reload
        sale.propose!
        sale.invoice! if rand > 0.4
        sale
      end

      def create_purchase(options = {})
        currency = options[:currency] || @currency
        c = Nomen::Currency.find(currency)
        raise "What? #{currency.inspect}" unless c
        journal = Journal.find_or_create_by!(
          currency: currency,
          name: "#{c.human_name(locale: :eng)} purchases",
          code: 'P' + currency.to_s,
          nature: :purchases
        )
        options[:nature] ||= PurchaseNature.create_with(name: "#{currency} #{rand(100_000).to_s(36)} purchase").find_or_create_by!(
          active: true,
          currency: currency,
          with_accounting: true,
          journal: journal
        )
        supplier_type = Variant.supplier_types.sample
        purchase = Purchase.create!(options)
        variants = []
        (2 + rand(4)).times do |_i|
          next unless (variant = Variant.purchaseables(supplier_type).sample)
          next if variants.include? variant
          variants << variant
          purchase.items.create!(
            unit_pretax_amount: variant.unit_pretax_amount,
            quantity: variant.purchase_quantity,
            variant_id: variant.id,
            tax: Tax.where('amount >= ?', rand > 0.2 ? 19 : 0).to_a.sample
          )
        end
        unless purchase.items.any?
          purchase.destroy
          return nil
        end
        purchase.reload
        purchase.propose!
        purchase.confirm!
        purchase.invoice! if rand > 0.1
        purchase
      end

      def create_outgoing_parcel(options = {})
        return nil unless options[:sale]
        sale = options[:sale]

        attributes = {
          sale_id: sale.id,
          nature: :outgoing,
          recipient: sale.client,
          address: sale.delivery_address || default_mail_address(sale.client),
          with_delivery: rand > 0.3,
          items_attributes: sale.items.each_with_object({}) do |item, h|
            product = Product.where('? BETWEEN COALESCE(born_at, ?) AND COALESCE(dead_at, ?)', Time.zone.now, Time.zone.now, Time.zone.now)
                             .where(variant: item.variant).to_a.sample
            unless product
              product = item.variant.products.create!(
                initial_population: item.quantity * rand(30),
                born_at: Date.today - rand(600).days
              )
            end
            v = Variant.find(item.variant.reference_name)
            next if v && !v.deliverable?
            set_storable(product.category)
            product.variant.reload
            product.reload
            h[item.id.to_s] = {
              source_product_id: product.id,
              pretax_amount: item.pretax_amount,
              population: product.population_counting_unitary? ? 1 : item.quantity,
              sale_item: item
            }
          end
        }
        parcel = Parcel.create! attributes
        unless parcel.items.any?
          parcel.destroy
          return nil
        end
        parcel.order!
        parcel.prepare!
        parcel.check!
        parcel.give! unless parcel.with_delivery
        parcel
      end

      def create_incoming_parcel(options = {})
        return nil unless options[:purchase]
        purchase = options[:purchase]
        attributes = {
          purchase_id: purchase.id,
          nature: :incoming,
          sender: purchase.supplier,
          address: default_mail_address(Entity.of_company),
          storage: find_or_create_building,
          with_delivery: rand > 0.7,
          items_attributes: purchase.items.each_with_object({}) do |item, h|
            next unless item.variant.of_variety?(:matter)
            v = Variant.find(item.variant.reference_name)
            next if v && !v.deliverable?
            set_storable(item.variant.category)
            item.variant.reload
            item.reload
            name = item.variant.population_counting_unitary? && Nomen::Variety.find(:bioproduct) >= item.variant.variety ? FFaker::NameFR.first_name : item.variant.name + ' ' + Date.today.l
            h[item.id.to_s] = {
              variant: item.variant,
              product_identification_number: rand(50_000).to_s + name.codeize[0..15],
              product_name: name,
              pretax_amount: item.pretax_amount,
              population: item.variant.population_counting_unitary? ? 1 : item.quantity,
              purchase_item: item
            }
          end
        }
        parcel = Parcel.create! attributes
        unless parcel.items.any?
          parcel.destroy
          return nil
        end
        parcel.order!
        parcel.prepare!
        parcel.check!
        parcel.give! unless parcel.with_delivery
        parcel
      end

      def create_delivery
        return nil if rand > 0.95
        delivery = Delivery.new(mode: :us)
        return nil if delivery.available_parcels.count < 3
        delivery.save!
        delivery.available_parcels.find_each do |p|
          p.update!(delivery: delivery)
        end
        delivery.order
        delivery.prepare
        delivery.check
        delivery.start
        Timecop.travel(Time.zone.now + 7.hours + rand(59).minutes)
        delivery.finish
        Timecop.return
        delivery
      end

      def create_incoming_payment(options = {})
        options[:mode] ||= find_or_create_incoming_payment_mode(options)
        options[:received] = true
        options[:to_bank_at] ||= Time.zone.now
        options[:paid_at] ||= Time.zone.now
        IncomingPayment.create!(options)
      end

      def create_outgoing_payment(options = {})
        options[:currency] ||= options[:affair].currency if options[:affair]
        options[:mode] ||= find_or_create_outgoing_payment_mode(options.slice(:currency))
        options[:delivered] = true
        options[:to_bank_at] ||= Time.zone.now
        options[:paid_at] ||= Time.zone.now
        options[:responsible] ||= find_or_create_user(locked: false)
        OutgoingPayment.create!(options)
      end

      def create_inventory
        financial_year = current_financial_year
        return nil if financial_year.inventories.any?
        inventory = Inventory.new(
          name: financial_year.name,
          financial_year: financial_year,
          responsible: User.find(User.stamper).person
        )
        inventory.build_missing_items
        inventory.items.each do |item|
          next if rand > 0.17
          item.actual_population = (item.actual_population * (5 + rand) / 6).round(1)
        end
        inventory.save!
        inventory.reflect!
        inventory
      end

      # def create_financial_year_exchange(options = {})
      #   options[:started_on] ||= (@on - 1.month).beginning_of_month
      #   options[:stopped_on] ||= options[:started_on].end_of_month
      #   financial_year = FinancialYear.at(options[:started_on])
      #   unless financial_year.accountant
      #     accountant = nil
      #     if financial_year.previous
      #       accountant = financial_year.previous.accountant
      #     end
      #     accountant ||= find_or_create_entity(supplier: true)
      #     financial_year.accountant = accountant
      #     financial_year.save!
      #     index = Journal.where('code like ?', 'JCR%').count + 1
      #     journal = Journal.create_with(code: 'JCR' + index.to_s, name: entity.name)
      #                      .find_or_create_by(accountant: accountant, nature: :various)
      #   end
      #   FinancialYearExchange.create!(options.merge(financial_year: financial_year))
      # end

      def next!
        user = User.all.sample
        User.stamper = user
        ::I18n.locale = @locale # user.language
        @on += 1
      end

      def travel
        Timecop.travel(@on)
        yield
        Timecop.return
      end

      def run
        @on = @started_on
        travel do
          Preference.set!(:language, @locale)
          Preference.set!(:country, @country)
          ::I18n.locale = @locale
          Tax.load_defaults
          Account.load_defaults
          current_financial_year
        end
        last_month = nil
        last_year = nil
        while on < @stopped_on
          if day == 1 || last_month.nil?
            if month == 1 || last_year.nil?
              print "\n#{year}"
              last_year = year
            end
            print "\n"
            print month.to_s.rjust(2, ' ') + ': '
            last_month = month
          end
          print strftime('%a')[0..0]
          print '|' if sunday?

          if rand > 0.1
            travel do
              run_day!
            end
          end
          next!
        end
        puts '!'
      end

      def run_day!
        if (1..5).cover?(wday) && bank_balance < @cash_maximum
          # Add sales
          5.times do
            next unless rand > 0.7
            client = find_or_create_entity(client: true)
            sale = create_sale(client: client)
            next unless sale
            print 's'.yellow
            if sale.invoice? && rand > 0.2
              print 'k'.yellow if create_outgoing_parcel(sale: sale)
            end
            if rand > 0.3
              create_incoming_payment(payer: client, affair: sale.affair, amount: sale.amount)
              print 'w'.yellow
            end
          end
        end

        # if self.saturday?
        #   # Add international sales
        #   1.times do
        #     next unless rand > 0.7
        #     client = self.find_or_create_entity(client: true, country: [:us, :ca, :jp].sample)
        #     self.create_sale(client: client, currency: [:USD, :JPY].sample)
        #     print 'i'.yellow
        #   end
        # end

        # Inventory of end of year
        if month == current_financial_year.stopped_on.month && 17 < mday && mday <= 24 && friday?
          print 'h'.red if create_inventory
        end

        if monday?
          # Check old sale
          Sale.where.not(state: :invoice).where('updated_at >= ?', Time.zone.now - 30.days).find_each do |sale|
            next if rand > 0.8 || sale.items.empty?
            if sale.estimate? && rand > 0.75
              sale.abort!
              print 'a'.cyan
            end
            if sale.estimate? && rand > 0.5
              sale.confirm!
              print 'c'.cyan
            end
            if sale.order? && rand > 0.5
              sale.invoice!
              print 'i'.cyan
            end
            if sale.invoice? && rand > 0.93
              sale.build_credit.save!
              print 'r'.cyan
            end
          end

          Sale.where(state: :invoice).where('updated_at >= ?', Time.zone.now - 30.days).find_each do |sale|
            if sale.parcels.empty? && rand > 0.6
              print 'k'.cyan if create_outgoing_parcel(sale: sale)
            end
            next if sale.affair.credit >= sale.affair.debit # sale.affair.closed?
            if rand > 0.5
              create_incoming_payment(payer: sale.client, affair: sale.affair, amount: sale.amount)
              print 'w'.cyan
            end
          end

          Purchase.where.not(state: :invoice).where('updated_at >= ?', Time.zone.now - 30.days).find_each do |purchase|
            next unless rand > 0.5
            if purchase.can_abort? && rand > 0.5
              purchase.abort!
              print 'x'.cyan
            end
            if purchase.can_correct? && rand > 0.9
              purchase.correct!
              print 'z'.cyan
            end
            if purchase.can_invoice? && rand > 0.4
              purchase.invoice!
              print 'y'.cyan
            end
          end
          Purchase.where(state: :invoice).where('updated_at >= ?', Time.zone.now - 30.days).find_each do |purchase|
            if purchase.parcels.empty? && rand > 0.4
              print 'q'.cyan if create_incoming_parcel(purchase: purchase)
            end
            next if purchase.affair.credit <= purchase.affair.debit # purchase.affair.closed?
            if rand > 0.5
              create_outgoing_payment(payee: purchase.supplier, affair: purchase.affair, amount: purchase.amount)
              print 'o'.cyan
            end
          end

          # # Add deposit
          # 1.times do
          #   next unless rand > 0.6
          #   print 'd'.green
          # end
        end

        if tuesday?
          print 'j'.red if create_delivery
        end

        if (1..6).cover?(wday) && bank_balance > @cash_minimum
          # Add purchase
          5.times do
            next unless rand > 0.95
            supplier = find_or_create_entity(supplier: true)
            purchase = create_purchase(supplier: supplier)
            next unless purchase
            print 'p'.red
            if (purchase.order? || purchase.invoice?) && rand > 0.1
              print 'q'.red if create_incoming_parcel(purchase: purchase)
            end
            if rand > 0.05 && purchase.invoice?
              create_outgoing_payment(payee: supplier, affair: purchase.affair, amount: purchase.amount)
              print 'o'.red
            end
          end
        end

        # if self.tuesday? && self.mday <= 7
        #   if FinancialYearExchange.opened.any?
        #     FinancialYearExchange.opened.last.close!
        #   end
        #   stopped_on = (self.on - 7.months).end_of_month
        #   self.create_financial_year_exchange(started_on: stopped_on.beginning_of_month, stopped_on: stopped_on)
        #   print 'x'.magenta
        # end
      end
    end
  end
end

task fake: :environment do
  Ekylibre::Tenant.switch! ENV['TENANT']
  Ekylibre::Fake.run currency: ENV['CURRENCY'], env: ENV['FAKE_ENV']
end
