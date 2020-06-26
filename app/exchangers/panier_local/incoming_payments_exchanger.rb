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
      data, errors = open_and_decode_file(file)

      valid = errors.all?(&:empty?)

      # check if financial year exist
      fy_start = FinancialYear.at(data.first.invoiced_at)
      fy_stop = FinancialYear.at(data.last.invoiced_at)

      if fy_start.nil? && fy_stop.nil?
        w.error 'Need a FinancialYear'
        valid = false
      end

      if find_payment_mode_by_provider.nil? && (default_cash rescue nil).nil?
        w.error 'Need a default bank cash account'
        valid = false
      end

      valid
    end

    def import
      data, _errors = open_and_decode_file(file)

      payment_mode = find_or_create_payment_mode

      incoming_payments_info = data.group_by { |d| d.payment_reference_number }

      w.count = incoming_payments_info.size

      incoming_payments_info.each do |_payment_reference_number, incoming_payment_info|
        find_or_create_incoming_payment(incoming_payment_info, payment_mode)

        w.check_point
      end
    end

    def find_or_create_payment_mode
      Maybe(find_payment_mode_by_provider)
        .recover { create_incoming_payment_mode(default_cash) }
        .or_raise
    end

    # @return [IncomingPaymentMode, nil]
    def find_payment_mode_by_provider
      unwrap_one('incoming_payment') { IncomingPaymentMode.of_provider_name(provider_vendor, provider_name) }
    end

    # @return [Cash]
    def default_cash
      @cash = unwrap_one('default bank account', exact: true) { Cash.bank_accounts.where(by_default: true) }
    end

    # @param [Cash] cash
    # @return [IncomingPaymentMode]
    def create_incoming_payment_mode(cash)
      IncomingPaymentMode.create!(
        cash: cash,
        name: tl(:incoming_payment_mode_name),
        with_accounting: true,
        with_deposit: false,
        provider: provider_value
      )
    end

    # @param [OpenStruct] incoming_payment_info
    # @param [IncomingPaymentMode] payment_mode
    # @return [IncomingPayment]
    def find_or_create_incoming_payment(incoming_payment_info, payment_mode)
      reference_number = unwrap_one('reference_number', exact: true) { incoming_payment_info.map(&:sale_reference_number).uniq }

      Maybe(find_incoming_payment_by_provider(reference_number))
        .recover { create_incoming_payment(incoming_payment_info, reference_number, payment_mode) }
        .or_raise
    end

    # @param [String] reference_number
    # @return [IncomingPayment, nil]
    def find_incoming_payment_by_provider(reference_number)
      unwrap_one('incoming payment') do
        IncomingPayment.of_provider_name(:panier_local, :incoming_payments)
                       .of_provider_data(:sale_reference_number, reference_number)
      end
    end

    # @param [OpenStruct] incoming_payment_info
    # @param [String] reference_number
    # @param [IncomingPaymentMode] payment_mode
    # @return [IncomingPayment]
    def create_incoming_payment(incoming_payment_info, reference_number, payment_mode)
      grouped_lines = incoming_payment_info.group_by do |line|
        account_number = line.account_number

        if account_number.start_with?(client_account_radix)
          :client
        elsif account_number.start_with?('51')
          :bank
        else
          :unknown
        end
      end

      client_info = unwrap_one('client info', exact: true) { grouped_lines.fetch(:client, []) }
      bank_info = unwrap_one('bank info', exact: true) { grouped_lines.fetch(:bank, []) }

      entity = find_or_create_entity(client_info.entity_name, client_info.account_number, client_info.entity_code)

      IncomingPayment.create!(
        mode: payment_mode,
        paid_at: bank_info.invoiced_at.to_datetime,
        to_bank_at: bank_info.invoiced_at.to_datetime,
        amount: get_incoming_payment_amount(bank_info),
        payer: entity,
        received: true,
        responsible: responsible,
        provider: provider_value(sale_reference_number: reference_number)
      )
    end

    # @param [OpenStruct] info
    # @return [Float]
    def get_incoming_payment_amount(info)
      if info.payment_item_direction == 'D'
        info.payment_item_amount
      elsif info.payment_item_direction == 'C'
        info.payment_item_amount * -1
      else
        raise StandardError.new("Can't create IncomingPayment. Payment item direction provided isn't a letter supported")
      end
    end

    def provider_name
      :incoming_payments
    end

    def open_and_decode_file(file)
      # Open and Decode: CSVReader::read(file)
      rows = ActiveExchanger::CsvReader.new(col_sep: ';').read(file)
      parser = ActiveExchanger::CsvParser.new(NORMALIZATION_CONFIG)

      parser.normalize(rows)
    end

  end
end
