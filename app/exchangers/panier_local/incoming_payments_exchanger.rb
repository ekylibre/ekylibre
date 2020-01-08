module PanierLocal
  class IncomingPaymentsExchanger < ActiveExchanger::Base

    NORMALIZATION_CONFIG = [
      {col: 1, name: :invoiced_at, type: :date, constraint: :not_nil},
      {col: 3, name: :journal_nature, type: :string},
      {col: 4, name: :account_number, type: :integer, constraint: :not_nil},
      {col: 5, name: :entity_name, type: :string, constraint: :not_nil},
      {col: 6, name: :entity_code, type: :integer, constraint: :not_nil},
      {col: 7, name: :payment_reference_number, type: :integer, constraint: :not_nil},
      {col: 8, name: :payment_description, type: :string},
      {col: 9, name: :payment_item_amount, type: :float, constraint: :greater_or_equal_to_zero},
      {col: 10, name: :payment_item_sens, type: :string},
    ]




    def check
      # Imports incoming_payment entries into incoming payment to make accountancy in CSV format
      # filename example : ECRITURES.CSV
      # Columns are:
      #  0 - A: journal_entry_items_line : "1"
      #  1 - B: printed_on : "01/01/2017"
      #  2 - C: journal code : "50"
      #  3 - D: journal nature : "BANQUE"
      #  4 - E: account number : "512"
      #  5 - F: entity name : "AB EPLUCHES"
      #  6 - G: entity number : "133"
      #  7 - H: journal_entry number : "336"
      #  8 - I: journal_entry label : "Versement"
      #  9 - J: amount : '44,24'
      #  10 - K: sens : 'D'

      # Ouverture et décodage: CSVReader::read(file)
      rows = ActiveExchanger::CsvReader.new.read(file)

      parser = ActiveExchanger::CsvParser.new(NORMALIZATION_CONFIG)

      data, errors = parser.normalize(rows)

      valid = errors.reject(&:empty?).empty?
      # source = File.read(file)
      # detection = CharlockHolmes::EncodingDetector.detect(source)
      # rows = CSV.read(file, headers: true, encoding: detection[:encoding], col_sep: ';')
      # w.count = rows.size
      # valid = true

      last_line = rows.size - 1

      # check if financial year exist
      fy_start = FinancialYear.at(Date.parse(rows.first[1].to_s))
      fy_stop = FinancialYear.at(Date.parse(rows[last_line][1].to_s))
      unless fy_start && fy_stop
        w.warn 'Need a FinancialYear'
        valid = false
      end

      # find a responsible
      responsible = User.employees.first
      unless responsible
        w.error 'No responsible found'
        valid = false
      end

      # check if cash and incoming payment mode exist
      c = Cash.bank_accounts.first
      if c
        ipm = IncomingPaymentMode.where(cash_id: c.id, with_accounting: true).order(:name)
        if ipm.any?
          valid = true
        else
          w.warn 'Need an incoming payment link to cash account'
          valid = false
        end
      else
        w.warn 'Need a bank cash account'
        valid = false
      end

      # w.info "Requirement is #{valid}".inspect.green


      # rows.each_with_index do |row, index|
      #   line_number = index + 2
      #   prompt = "L#{line_number.to_s.yellow}"
      #   r = {
      #     payment_item_line: (row[0].blank? ? nil : row[0]),
      #     invoiced_at:        (row[1].blank? ? nil : Date.parse(row[1].to_s)),
      #     journal_nature: (row[3].blank? ? nil : row[3].to_s),
      #     account_number:   (row[4].blank? ? nil : row[4].upcase),
      #     entity_name: (row[5].blank? ? nil : row[5].to_s),
      #     entity_code: (row[6].blank? ? nil : row[6].to_s),
      #     payment_reference_number: (row[7].blank? ? nil : row[7].to_s),
      #     payment_description: (row[8].blank? ? nil : row[8].to_s),
      #     payment_item_amount: (row[9].blank? ? nil : row[9].tr(',', '.').to_f),
      #     payment_item_sens: (row[10].blank? ? nil : row[10].to_s)
      #   }.to_struct

        # # check data quality basics on file
        # unless r.payment_item_amount >= 0.0
        #   valid = false
        # end

        # if r.account_number.nil? || r.invoiced_at.nil? || r.entity_name.nil? || r.entity_code.nil? || r.payment_reference_number.nil?
        #   valid = false
        # end

        # w.info "Line data quality is #{valid}".inspect.green
      # end
      valid
    end

    def import
      # Ouverture et décodage: CSVReader::read(file)
      rows = ActiveExchanger::CsvReader.new.read(file)

      # source = File.read(file)
      # detection = CharlockHolmes::EncodingDetector.detect(source)
      # rows = CSV.read(file, headers: true, encoding: detection[:encoding], col_sep: ';')
      w.count = rows.size


      # # create or find journal for sale nature
      # c = Cash.bank_accounts.first
      # ipm = IncomingPaymentMode.where(cash_id: c.id, with_accounting: true).order(:name).last
      # responsible = User.employees.first

      parser = ActiveExchanger::CsvParser.new(NORMALIZATION_CONFIG)

      data, errors = parser.normalize(rows)

      sales_info = data.group_by { |d| d.payment_reference_number }

      sales_info.each { |_sale_reference_number, sale_info| incoming_payment_creation(sale_info) }
      # rows.each_with_index do |row, index|
      #   line_number = index + 2
      #   prompt = "L#{line_number.to_s.yellow}"
      #   r = {
      #     payment_item_line: (row[0].blank? ? nil : row[0]),
      #     invoiced_at:        (row[1].blank? ? nil : Date.parse(row[1].to_s)),
      #     journal_nature: (row[3].blank? ? nil : row[3].to_s),
      #     account_number:   (row[4].blank? ? nil : row[4].upcase),
      #     entity_name: (row[5].blank? ? nil : row[5].to_s),
      #     entity_code: (row[6].blank? ? nil : row[6].to_s),
      #     payment_reference_number: (row[7].blank? ? nil : row[7].to_s),
      #     payment_description: (row[8].blank? ? nil : row[8].to_s),
      #     payment_item_amount: (row[9].blank? ? nil : row[9].tr(',', '.').to_f),
      #     payment_item_sens: (row[10].blank? ? nil : row[10].to_s)
      #   }.to_struct

        # next if r.payment_item_amount == 0.0

        # find or create an entity when being on line like 411....
        # if r.entity_name && r.account_number.start_with?('411')
        #   entity = Entity.where('codes ->> ? = ?', 'panier_local', r.entity_code).first
        #   last_name = r.entity_name.mb_chars.capitalize
        #   unless entity
        #     # check entity account
        #     acc = Account.find_or_initialize_by(number: r.account_number)
        #     attributes = {name: r.entity_name}
        #     attributes[:centralizing_account_name] = r.account_number.start_with?('401') ? 'suppliers' : 'clients'
        #     attributes[:nature] = 'auxiliary'
        #     aux_number = r.account_number[3, r.account_number.length]
        #     if aux_number.match(/\A0*\z/).present?
        #       w.info "We can't import auxiliary number #{aux_number} with only 0. Mass change number in your file before importing"
        #       attributes[:auxiliary_number] = '00000A'
        #     else
        #       attributes[:auxiliary_number] = aux_number
        #     end
        #     acc.attributes = attributes
        #     acc.save!
        #     w.info "account saved ! : #{acc.label.inspect.red}"
        #     # check entity
        #     w.info "Create entity and link account"
        #     entity = Entity.where('last_name ILIKE ?', last_name).first
        #     entity ||= Entity.new
        #     entity.nature = :organization
        #     entity.last_name = last_name
        #     entity.codes = { 'panier_local' => r.entity_code }
        #     entity.active = true
        #     entity.client = true
        #     entity.client_account_id = acc.id
        #     entity.save!
        #     w.info prompt
        #     w.info "Entity created ! : #{entity.full_name.inspect.red}"
        #   end
        # end

        # get the entity when being on the line like 512..
        entity = Entity.where('codes ->> ? = ?', 'panier_local', r.entity_code).first

        if r.account_number.start_with?('51') && entity
          incoming_payment = IncomingPayment.where('providers ->> ? = ?', 'panier_local', r.payment_reference_number).where(payer: entity, paid_at: r.invoiced_at.to_datetime).first
          unless incoming_payment
            if r.payment_item_sens == 'D'
              amount = r.payment_item_amount
            elsif r.payment_item_sens == 'C'
              amount = r.payment_item_amount * -1
            end
            incoming_payment = IncomingPayment.create!(
                                                      mode: ipm,
                                                      paid_at: r.invoiced_at.to_datetime,
                                                      to_bank_at: r.invoiced_at.to_datetime,
                                                      amount: amount,
                                                      payer: entity,
                                                      received: true,
                                                      responsible: responsible,
                                                      providers: {'panier_local' => r.payment_reference_number}
                                                    )
            w.info "Incoming Payment created ! : #{incoming_payment.amount}".inspect.green
          end
        end
        w.check_point
      # end
    end

    def incoming_payment_creation(sale_info)

      # create or find journal for sale nature
      c = Cash.bank_accounts.first
      ipm = IncomingPaymentMode.where(cash_id: c.id, with_accounting: true).order(:name).last
      responsible = User.employees.first

      entity = get_or_create_entity(sale_info)

      # # find or create an entity when being on line like 411....
      #   if r.entity_name && r.account_number.start_with?('411')
      #     entity = Entity.where('codes ->> ? = ?', 'panier_local', r.entity_code).first
      #     last_name = r.entity_name.mb_chars.capitalize
      #     unless entity
      #       # check entity account
      #       acc = Account.find_or_initialize_by(number: r.account_number)
      #       attributes = {name: r.entity_name}
      #       attributes[:centralizing_account_name] = r.account_number.start_with?('401') ? 'suppliers' : 'clients'
      #       attributes[:nature] = 'auxiliary'
      #       aux_number = r.account_number[3, r.account_number.length]
      #       if aux_number.match(/\A0*\z/).present?
      #         w.info "We can't import auxiliary number #{aux_number} with only 0. Mass change number in your file before importing"
      #         attributes[:auxiliary_number] = '00000A'
      #       else
      #         attributes[:auxiliary_number] = aux_number
      #       end
      #       acc.attributes = attributes
      #       acc.save!
      #       w.info "account saved ! : #{acc.label.inspect.red}"
      #       # check entity
      #       w.info "Create entity and link account"
      #       entity = Entity.where('last_name ILIKE ?', last_name).first
      #       entity ||= Entity.new
      #       entity.nature = :organization
      #       entity.last_name = last_name
      #       entity.codes = { 'panier_local' => r.entity_code }
      #       entity.active = true
      #       entity.client = true
      #       entity.client_account_id = acc.id
      #       entity.save!
      #       w.info prompt
      #       w.info "Entity created ! : #{entity.full_name.inspect.red}"
      #     end
      #   end

        # get the entity when being on the line like 512..
        entity = Entity.where('codes ->> ? = ?', 'panier_local', r.entity_code).first

        if r.account_number.start_with?('51') && entity
          incoming_payment = IncomingPayment.where('providers ->> ? = ?', 'panier_local', r.payment_reference_number).where(payer: entity, paid_at: r.invoiced_at.to_datetime).first
          unless incoming_payment
            if r.payment_item_sens == 'D'
              amount = r.payment_item_amount
            elsif r.payment_item_sens == 'C'
              amount = r.payment_item_amount * -1
            end
            incoming_payment = IncomingPayment.create!(
                                                      mode: ipm,
                                                      paid_at: r.invoiced_at.to_datetime,
                                                      to_bank_at: r.invoiced_at.to_datetime,
                                                      amount: amount,
                                                      payer: entity,
                                                      received: true,
                                                      responsible: responsible,
                                                      providers: {'panier_local' => r.payment_reference_number}
                                                    )
            w.info "Incoming Payment created ! : #{incoming_payment.amount}".inspect.green
          end
        end

    end


    def get_or_create_entity(sale_info)
      entity = Entity.where('codes ->> ? = ?', 'panier_local', sale_info.first.entity_code.to_s)
      if entity.any?
          entity.first
      else
        account = create_entity_account(sale_info)
        create_entity(sale_info, account)
      end
    end



    def create_entity_account(sale_info)
      client_sale_info = sale_info.select {|item| item.account_number.to_s.start_with?('411')}.first
      if client_sale_info.present?
        client_number_account = client_sale_info.account_number.to_s
        acc = Account.find_or_initialize_by(number: client_number_account)#!

        attributes = {
                      name: client_sale_info.entity_name,
                      centralizing_account_name: 'clients',
                      nature: 'auxiliary'
                    }

        aux_number = client_number_account[3, client_number_account.length]

        if aux_number.match(/\A0*\z/).present?
          w.info "We can't import auxiliary number #{aux_number} with only 0. Mass change number in your file before importing"
          attributes[:auxiliary_number] = '00000A'
        else
          attributes[:auxiliary_number] = aux_number
        end
        acc.attributes = attributes
        acc
      end
    end


    def create_entity(sale_info, acc)
      client_sale_info = sale_info.select {|item| item.account_number.to_s.start_with?('411')}.first
      last_name = client_sale_info.entity_name.mb_chars.capitalize

      w.info "Create entity and link account"
      entity = Entity.new(
        nature: :organization,
        last_name: last_name,
        codes: { 'panier_local' => client_sale_info.entity_code },
        active: true,
        client: true,
        client_account_id: acc.id
      )

      entity
    end



  end
end
