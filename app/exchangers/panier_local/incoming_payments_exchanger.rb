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
      {col: 10, name: :payment_item_direction, type: :string},
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

      rows = ActiveExchanger::CsvReader.new.read(file)

      parser = ActiveExchanger::CsvParser.new(NORMALIZATION_CONFIG)

      data, errors = parser.normalize(rows)

      valid = errors.all?(&:empty?)

      # check if financial year exist
      fy_start = FinancialYear.at(Date.parse(rows.first[1].to_s))
      fy_stop = FinancialYear.at(Date.parse(rows[-1][1].to_s))
      unless fy_start && fy_stop
        w.warn 'Need a FinancialYear'
        valid = false
      end

      # find a responsible
      responsible = User.employees.first
      if responsible.nil?
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
          w.error 'Need an incoming payment link to cash account'
          valid = false
        end
      else
        w.warn 'Need a default bank cash account'
        valid = false
      end

      valid
    end

    def import
      rows = ActiveExchanger::CsvReader.new.read(file)

      parser = ActiveExchanger::CsvParser.new(NORMALIZATION_CONFIG)

      data, _errors = parser.normalize(rows)

      sales_info = data.group_by { |d| d.payment_reference_number }

      sales_info.each { |_payment_reference_number, sale_info| incoming_payment_creation(sale_info) }
    end

    def incoming_payment_creation(sale_info)
      c = Cash.bank_accounts.first
      ipm = IncomingPaymentMode.where(cash_id: c.id, with_accounting: true).order(:name).last
      responsible = User.employees.first

      client_sale_info = sale_info.select {|item| item.account_number.to_s.start_with?('411')}.first
      bank_sale_info = sale_info.select {|item| item.account_number.to_s.start_with?('51')}.first

      if bank_sale_info.present? && client_sale_info.present?
        entity = get_or_create_entity(sale_info, client_sale_info)
        incoming_payment = IncomingPayment.of_provider_name(:panier_local, :incoming_payments).find_by("provider -> 'data' ->> 'payment_reference_number' = ?", bank_sale_info.payment_reference_number.to_s)
                                          .where(payer: entity, paid_at: bank_sale_info.invoiced_at.to_datetime).first
        if incoming_payment.nil?
          if bank_sale_info.payment_item_direction == 'D'
            amount = bank_sale_info.payment_item_amount
          elsif bank_sale_info.payment_item_direction == 'C'
            amount = bank_sale_info.payment_item_amount * -1
          end
          incoming_payment = IncomingPayment.create!(
                                                    mode: ipm,
                                                    paid_at: bank_sale_info.invoiced_at.to_datetime,
                                                    to_bank_at: bank_sale_info.invoiced_at.to_datetime,
                                                    amount: amount,
                                                    payer: entity,
                                                    received: true,
                                                    responsible: responsible,
                                                    provider: { vendor: :panier_local, name: :incoming_payments, id: options[:import_id], data: { payment_reference_number: bank_sale_info.payment_reference_number.to_s } }
                                                  )
        end
      end
    end

    def get_or_create_entity(sale_info, client_sale_info)
      entity = Entity.where('codes ->> ? = ?', 'panier_local', sale_info.first.entity_code.to_s)
      if entity.any?
          entity.first
      else
        account = create_entity_account(sale_info, client_sale_info)
        create_entity(sale_info, account, client_sale_info)
      end
    end

    def create_entity_account(sale_info, client_sale_info)
      client_number_account = client_sale_info.account_number.to_s
      acc = Account.find_or_initialize_by(number: client_number_account)

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

    def create_entity(sale_info, acc, client_sale_info)
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
