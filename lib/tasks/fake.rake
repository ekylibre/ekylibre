task fake: :environment do
  class Fake
    attr_reader :on, :currency
    delegate :monday?, :tuesday?, :wenesday?, :thursday?, :friday?, :saturday?, :sunday?,
             :day, :month, :year, :mday, :wday, :strftime, to: :on

    def initialize(options = {})
      @currency = options[:currency] || 'EUR'
      @on = options[:on] || Date.civil(2015, 9, 1)
    end

    def entity(options = {})
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
        u = User.where(locked: false).to_a.sample
        entity.observations.create!(creator: u, author: u, content: FFaker::HipsterIpsum.words(15).join(' '))
      end

      # Adds
      if entity.mails.empty? && rand > 0.1
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

    def sale(options = {})
      currency = options[:currency] || @currency
      c = Nomen::Currency.find(currency)
      raise "What? #{currency.inspect}" unless c
      journal = Journal.find_or_create_by!(
        currency: currency,
        name: "#{c.human_name(locale: :eng)} sales",
        code: 'S' + currency.to_s,
        nature: :sales
      )
      catalog = Catalog.create_with(name: "Sales #{currency}").find_or_create_by!(usage: :sale, currency: currency, code: "SALE#{currency}")
      options[:nature] ||= SaleNature.create_with(name: "#{currency} #{rand(100_000).to_s(36)} sale").find_or_create_by!(
        active: true,
        currency: currency,
        with_accounting: true,
        catalog: catalog,
        journal: journal
      )
      sale = Sale.create!(options)
      (1 + rand(4)).times do
        sale.items.create!(
          compute_from: :unit_pretax_amount,
          unit_pretax_amount: (rand(20) + 80).round(c.precision),
          quantity: (rand(3) + 7).round(2),
          variant: ProductNatureVariant.saleables.to_a.sample,
          tax: Tax.where('amount >= ?', rand > 0.2 ? 19 : 0).to_a.sample
        )
      end
      sale.reload
      sale.propose!
      sale.invoice! if rand > 0.4
      sale
    end

    def purchase(options = {})
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
      purchase = Purchase.create!(options)
      (1 + rand(4)).times do |_i|
        next if
        purchase.items.create!(
          unit_pretax_amount: (rand(10) + 40).round(c.precision),
          quantity: (rand(20) + 50).round(2),
          variant: ProductNatureVariant.purchaseables.to_a.sample,
          tax: Tax.where('amount >= ?', rand > 0.2 ? 19 : 0).to_a.sample
        )
      end
      purchase.reload
      purchase.propose!
      purchase.confirm!
      purchase.invoice! if rand > 0.1
      purchase
    end

    def incoming_payment(options = {})
      currency = options[:currency] || @currency
      c = Nomen::Currency.find(currency)
      raise "What? #{currency.inspect}" unless c
      cash_name = c.human_name(locale: :eng) + ' Bank'
      journal = options.delete(:journal) || Journal.find_or_create_by!(
        currency: currency,
        name: cash_name,
        code: 'B' + currency.to_s,
        nature: :bank
      )
      cash = options.delete(:cash) || Cash.create_with(name: cash_name).find_or_create_by!(
        nature: :bank_account,
        journal: journal,
        currency: currency,
        main_account: Account.find_or_create_by_number('5120' + currency.to_s.downcase.to_i(36).to_s)
      )
      options[:mode] ||= IncomingPaymentMode.create_with(name: "#{cash_name} transfer").find_or_create_by(
        cash: cash,
        with_accounting: true,
        active: true
      )
      options[:received] = true
      options[:to_bank_at] ||= Time.zone.now
      options[:paid_at] ||= Time.zone.now
      IncomingPayment.create!(options)
    end

    def outgoing_payment(options = {})
      currency = options[:currency] || @currency
      c = Nomen::Currency.find(currency)
      raise "What? #{currency.inspect}" unless c
      cash_name = c.human_name(locale: :eng) + ' Bank'
      journal = options.delete(:journal) || Journal.find_or_create_by!(
        currency: currency,
        name: cash_name,
        code: 'B' + currency.to_s,
        nature: :bank
      )
      cash = options.delete(:cash) || Cash.create_with(name: cash_name).find_or_create_by!(
        nature: :bank_account,
        journal: journal,
        currency: currency,
        main_account: Account.find_or_create_by_number('5120' + currency.to_s.downcase.to_i(36).to_s)
      )
      options[:mode] ||= OutgoingPaymentMode.create_with(name: "#{cash_name} transfer").find_or_create_by(
        cash: cash,
        with_accounting: true,
        active: true
      )
      options[:delivered] = true
      options[:to_bank_at] ||= Time.zone.now
      options[:paid_at] ||= Time.zone.now
      options[:responsible] ||= User.first
      OutgoingPayment.create!(options)
    end

    def financial_year_exchange(options = {})
      options[:started_on] ||= (@on - 1.month).beginning_of_month
      options[:stopped_on] ||= options[:started_on].end_of_month
      financial_year = FinancialYear.at(options[:started_on])
      unless financial_year.accountant
        accountant = nil
        if financial_year.previous
          accountant = financial_year.previous.accountant
        end
        accountant ||= entity(supplier: true)
        financial_year.accountant = accountant
        financial_year.save!
        index = Journal.where('code like ?', 'JCR%').count + 1
        journal = Journal.create_with(code: 'JCR' + index.to_s, name: entity.name)
                         .find_or_create_by(accountant: accountant, nature: :various)
      end
      FinancialYearExchange.create!(options.merge(financial_year: financial_year))
    end

    def next!
      User.stamper = User.all.sample
      @on += 1
    end

    def travel
      Timecop.travel(@on)
      yield
      Timecop.return
    end
  end

  Ekylibre::Tenant.switch! ENV['TENANT']
  last_month = nil
  last_year = nil
  fake = Fake.new currency: ENV['CURRENCY']
  while fake.on < Date.today
    if fake.day == 1 || last_month.nil?
      if fake.month == 1 || last_year.nil?
        print "\n#{fake.year}"
        last_year = fake.year
      end
      print "\n"
      print fake.month.to_s.rjust(2, ' ') + ': '
      last_month = fake.month
    end
    print fake.strftime('%a')[0..0]
    print '|' if fake.sunday?

    if rand > 0.1
      fake.travel do
        if (1..5).cover? fake.wday
          # Add sales
          5.times do
            next unless rand > 0.7
            client = fake.entity(client: true)
            sale = fake.sale(client: client)
            print 's'.yellow
            if rand > 0.3
              fake.incoming_payment(payer: client, affair: sale.affair, amount: sale.amount)
              print 'p'.yellow
            end
          end
        end

        # if fake.saturday?
        #   # Add international sales
        #   1.times do
        #     next unless rand > 0.7
        #     client = fake.entity(client: true, country: [:us, :ca, :jp].sample)
        #     fake.sale(client: client, currency: [:USD, :JPY].sample)
        #     print 'i'.yellow
        #   end
        # end

        if fake.monday?
          # Check old sale
          Sale.where.not(state: :invoice).where('updated_at >= ?', Time.now - 30.days).find_each do |s|
            next if rand > 0.8 || s.items.empty?
            if s.estimate? && rand > 0.75
              s.abort!
              print 'a'.cyan
            end
            if s.estimate? && rand > 0.5
              s.confirm!
              print 'c'.cyan
            end
            if s.order? && rand > 0.5
              s.invoice!
              print 'i'.cyan
            end
            if s.invoice? && rand > 0.93
              s.build_credit.save!
              print 'r'.cyan
            end
            s.affair.reload
            unless s.affair.closed?
              if (s.invoice? && rand > 0.5) || (s.order? && rand > 0.7)
                fake.incoming_payment(payer: s.client, affair: s.affair, amount: s.amount)
                print 'p'.cyan
              end
            end
          end

          # # Add deposit
          # 1.times do
          #   next unless rand > 0.6
          #   print 'd'.green
          # end
        end

        if (1..6).cover? fake.wday
          # Add purchase
          3.times do
            next unless rand > 0.95
            supplier = fake.entity(supplier: true)
            purchase = fake.purchase(supplier: supplier)
            print 'p'.red
            if rand > 0.05
              fake.outgoing_payment(payee: supplier, affair: purchase.affair, amount: purchase.amount)
              print 'o'.red
            end
          end
        end

        if fake.tuesday? && fake.mday <= 7
          if FinancialYearExchange.opened.any?
            FinancialYearExchange.opened.last.close!
          end
          stopped_on = (fake.on - 7.months).end_of_month
          fake.financial_year_exchange(started_on: stopped_on.beginning_of_month, stopped_on: stopped_on)
          print 'x'.magenta
        end
      end
    end
    fake.next!
  end
  puts '!'
end
