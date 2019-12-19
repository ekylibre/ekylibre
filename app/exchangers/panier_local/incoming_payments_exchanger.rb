module PanierLocal
  class IncomingPaymentsExchanger < ActiveExchanger::Base
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

      source = File.read(file)
      detection = CharlockHolmes::EncodingDetector.detect(source)
      rows = CSV.read(file, headers: true, encoding: detection[:encoding], col_sep: ';')
      w.count = rows.size
      valid = true

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

      # check if cash by default exist and incoming payment mode exist
      c = Cash.bank_accounts.find_by(by_default: true)
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

      w.info "Requirement is #{valid}".inspect.green

      rows.each_with_index do |row, index|
        line_number = index + 2
        prompt = "L#{line_number.to_s.yellow}"
        r = {
          payment_item_line: (row[0].blank? ? nil : row[0]),
          invoiced_at:        (row[1].blank? ? nil : Date.parse(row[1].to_s)),
          journal_nature: (row[3].blank? ? nil : row[3].to_s),
          account_number:   (row[4].blank? ? nil : row[4].upcase),
          entity_name: (row[5].blank? ? nil : row[5].to_s),
          entity_code: (row[6].blank? ? nil : row[6].to_s),
          payment_reference_number: (row[7].blank? ? nil : row[7].to_s),
          payment_description: (row[8].blank? ? nil : row[8].to_s),
          payment_item_amount: (row[9].blank? ? nil : row[9].tr(',', '.').to_f),
          payment_item_sens: (row[10].blank? ? nil : row[10].to_s)
        }.to_struct

        # check data quality basics on file
        unless r.payment_item_amount >= 0.0
          valid = false
        end

        if r.account_number.nil? || r.invoiced_at.nil? || r.entity_name.nil? || r.entity_code.nil? || r.payment_reference_number.nil?
          valid = false
        end

        w.info "Line data quality is #{valid}".inspect.green

      end
      valid
    end

    def import

      source = File.read(file)
      detection = CharlockHolmes::EncodingDetector.detect(source)
      rows = CSV.read(file, headers: true, encoding: detection[:encoding], col_sep: ';')
      w.count = rows.size

      # create or find journal for sale nature
      c = Cash.bank_accounts.find_by(by_default: true)
      ipm = IncomingPaymentMode.where(cash_id: c.id, with_accounting: true).order(:name).last
      responsible = User.employees.first

      rows.each_with_index do |row, index|
        line_number = index + 2
        prompt = "L#{line_number.to_s.yellow}"
        r = {
          payment_item_line: (row[0].blank? ? nil : row[0]),
          invoiced_at:        (row[1].blank? ? nil : Date.parse(row[1].to_s)),
          journal_nature: (row[3].blank? ? nil : row[3].to_s),
          account_number:   (row[4].blank? ? nil : row[4].upcase),
          entity_name: (row[5].blank? ? nil : row[5].to_s),
          entity_code: (row[6].blank? ? nil : row[6].to_s),
          payment_reference_number: (row[7].blank? ? nil : row[7].to_s),
          payment_description: (row[8].blank? ? nil : row[8].to_s),
          payment_item_amount: (row[9].blank? ? nil : row[9].tr(',', '.').to_f),
          payment_item_sens: (row[10].blank? ? nil : row[10].to_s)
        }.to_struct

        next if r.payment_item_amount == 0.0

        # find or create an entity when being on line like 411....
        if r.entity_name && r.account_number.start_with?('411')
          entity = Entity.where('codes ->> ? = ?', 'panier_local', r.entity_code).first
          last_name = r.entity_name.mb_chars.capitalize
          unless entity
            # check entity account
            acc = Account.find_or_initialize_by(number: r.account_number)
            attributes = {name: r.entity_name}
            attributes[:centralizing_account_name] = r.account_number.start_with?('401') ? 'suppliers' : 'clients'
            attributes[:nature] = 'auxiliary'
            aux_number = r.account_number[3, r.account_number.length]
            if aux_number.match(/\A0*\z/).present?
              w.info "We can't import auxiliary number #{aux_number} with only 0. Mass change number in your file before importing"
              attributes[:auxiliary_number] = '00000A'
            else
              attributes[:auxiliary_number] = aux_number
            end
            acc.attributes = attributes
            acc.save!
            w.info "account saved ! : #{acc.label.inspect.red}"
            # check entity
            w.info "Create entity and link account"
            entity = Entity.where('last_name ILIKE ?', last_name).first
            entity ||= Entity.new
            entity.nature = :organization
            entity.last_name = last_name
            entity.codes = { 'panier_local' => r.entity_code }
            entity.active = true
            entity.client = true
            entity.client_account_id = acc.id
            entity.save!
            w.info prompt
            w.info "Entity created ! : #{entity.full_name.inspect.red}"
          end
        end

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
                                                      providers: {'panier_local' => r.payment_reference_number, 'import_id' => options[:import_id]}
                                                    )
            w.info "Incoming Payment created ! : #{incoming_payment.amount}".inspect.green
          end
        end
        w.check_point
      end

    end
  end
end
