module PanierLocal
  class IncomingPaymentsExchanger < Base

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
    NORMALIZATION_CONFIG = [
      { col: 1, name: :invoiced_at, type: :date, constraint: :not_nil },
      { col: 3, name: :journal_nature, type: :string },
      { col: 4, name: :account_number, type: :string, constraint: :not_nil },
      { col: 5, name: :entity_name, type: :string, constraint: :not_nil },
      { col: 6, name: :entity_code, type: :string, constraint: :not_nil },
      { col: 7, name: :payment_reference_number, type: :integer, constraint: :not_nil },
      { col: 8, name: :payment_description, type: :string },
      { col: 9, name: :payment_item_amount, type: :float, constraint: :greater_or_equal_to_zero },
      { col: 10, name: :payment_item_direction, type: :string },
    ]

    def check
      rows = ActiveExchanger::CsvReader.new.read(file)

      parser = ActiveExchanger::CsvParser.new(NORMALIZATION_CONFIG)

      data, errors = parser.normalize(rows)

      valid = errors.all?(&:empty?)

      # check if financial year exist
      fy_start = FinancialYear.at(data.first.invoiced_at)
      fy_stop = FinancialYear.at(data.last.invoiced_at)

      if fy_start.nil? && fy_stop.nil?
        w.error 'Need a FinancialYear'
        valid = false
      end

      # check if cash by default exist and incoming payment mode exist
      cash = Cash.bank_accounts.find_by(by_default: true)
      if cash
        ipm = IncomingPaymentMode.where(cash_id: cash.id, with_accounting: true).order(:name)
        if ipm.empty?
          w.error 'Need an incoming payment link to cash account'
          valid = false
        end
      else
        w.error 'Need a default bank cash account'
        valid = false
      end

      valid
    end

    def import
      rows = ActiveExchanger::CsvReader.new.read(file)

      parser = ActiveExchanger::CsvParser.new(NORMALIZATION_CONFIG)

      data, _errors = parser.normalize(rows)

      incoming_payments_info = data.group_by { |d| d.payment_reference_number }

      incoming_payments_info.each { |_payment_reference_number, incoming_payment_info| incoming_payment_creation(incoming_payment_info) }
    end

    def incoming_payment_creation(incoming_payment_info)
      cash = Cash.bank_accounts.find_by(by_default: true)
      ipm = IncomingPaymentMode.where(cash_id: cash.id, with_accounting: true).order(:name).last
      responsible = import_resource.creator

      client_incoming_payment_info = incoming_payment_info.select { |item| item.account_number.to_s.start_with?('411') }.first
      bank_incoming_payment_info = incoming_payment_info.select { |item| item.account_number.to_s.start_with?('51') }.first

      if bank_incoming_payment_info.present? && client_incoming_payment_info.present?
        entity = get_or_create_entity(incoming_payment_info, client_incoming_payment_info)
        incoming_payment = IncomingPayment.of_provider_name(:panier_local, :incoming_payments)
                                          .of_provider_data(:payment_reference_number, bank_incoming_payment_info.payment_reference_number.to_s)
                                          .find_by(payer: entity, paid_at: bank_incoming_payment_info.invoiced_at.to_datetime)
        if incoming_payment.nil?
          if bank_incoming_payment_info.payment_item_direction == 'D'
            amount = bank_incoming_payment_info.payment_item_amount
          elsif bank_incoming_payment_info.payment_item_direction == 'C'
            amount = bank_incoming_payment_info.payment_item_amount * -1
          else
            raise StandardError.new("Can't create IncomingPayment. Payment item direction provided isn't a letter supported")
          end
          IncomingPayment.create!(
            mode: ipm,
            paid_at: bank_incoming_payment_info.invoiced_at.to_datetime,
            to_bank_at: bank_incoming_payment_info.invoiced_at.to_datetime,
            amount: amount,
            payer: entity,
            received: true,
            responsible: responsible,
            provider: { vendor: :panier_local, name: :incoming_payments, id: import_resource.id, data: { payment_reference_number: bank_incoming_payment_info.payment_reference_number.to_s } }
          )
        end
      end
    end

    def get_or_create_entity(incoming_payment_info, client_incoming_payment_info)
      entity = Entity.find_by('codes ->> ? = ?', 'panier_local', incoming_payment_info.first.entity_code.to_s)
      if entity
        entity
      else
        account = create_entity_account(client_incoming_payment_info)
        create_entity(account, client_incoming_payment_info)
      end
    end

    def create_entity_account(client_incoming_payment_info)
      client_number_account = client_incoming_payment_info.account_number.to_s
      acc = Account.find_or_initialize_by(number: client_number_account)
      attributes = {
        name: client_incoming_payment_info.entity_name,
        centralizing_account_name: 'clients',
        nature: 'auxiliary'
      }

      aux_number = client_number_account[3, client_number_account.length]

      if aux_number.match(/\A0*\z/).present?
        raise StandardError.new("Can't create account. Number provided can't be a radical class")
      else
        attributes[:auxiliary_number] = aux_number
      end
      acc.attributes = attributes
      acc
    end

    def create_entity(acc, client_incoming_payment_info)
      last_name = client_incoming_payment_info.entity_name.mb_chars.capitalize

      w.info "Create entity and link account"
      entity = Entity.new(
        nature: :organization,
        last_name: last_name,
        codes: { 'panier_local' => client_incoming_payment_info.entity_code },
        active: true,
        client: true,
        client_account_id: acc.id
      )
      entity
    end
  end
end
