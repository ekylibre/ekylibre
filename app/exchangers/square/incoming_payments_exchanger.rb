# frozen_string_literal: true

module Square
  class IncomingPaymentsExchanger < Base
    category :sales
    vendor :square

    # encoding UTF-16, separator tab
    NORMALIZATION_CONFIG = [
      { col: 0, name: :invoiced_on, type: :date, constraint: :not_nil },
      { col: 1, name: :invoiced_hour, type: :string, constraint: :not_nil },
      { col: 11, name: :amount, type: :currency, constraint: :not_nil },
      { col: 13, name: :cb_amount, type: :currency, constraint: :not_nil },
      { col: 15, name: :cash_amount, type: :currency, constraint: :not_nil },
      { col: 17, name: :other_amount, type: :currency, constraint: :not_nil },
      { col: 18, name: :other_mode, type: :string },
      { col: 21, name: :global_net_amount, type: :currency, constraint: :not_nil },
      { col: 22, name: :transaction_number, type: :string, constraint: :not_nil },
      { col: 23, name: :payment_number, type: :string, constraint: :not_nil },
      { col: 26, name: :pos_equipment_name, type: :string },
      { col: 29, name: :payment_url, type: :string },
      { col: 32, name: :pos_name, type: :string }
    ].freeze

    def check
      data, errors = open_and_decode_file(file)

      valid = errors.all?(&:empty?)
      if valid == false
        w.error "The file is invalid: #{errors}"
        return false
      end

      fy_start = FinancialYear.at(data.first.invoiced_on)
      fy_stop = FinancialYear.at(data.last.invoiced_on)

      if fy_start && fy_stop
        valid = true
      else
        w.error "No financial year exist between #{data.first.invoiced_on.l} and #{data.last.invoiced_on.l}"
        valid = false
      end

      w.count = data.size

      data.each do |incoming_payment|
        next if incoming_payment.global_net_amount.to_d <= 0.0

        if incoming_payment.cash_amount&.to_d != 0.0
          valid = true
        elsif incoming_payment.other_mode&.downcase == 'chèque' && incoming_payment.other_amount&.to_d != 0.0
          valid = true
        elsif incoming_payment.other_amount&.to_d != 0.0
          valid = true
        elsif incoming_payment.cb_amount&.to_d != 0.0
          valid = true
        else
          w.error "No payment configuration found. Please contact the support with Square Payment ID : #{incoming_payment.payment_number}"
          valid = false
        end
        w.check_point
      end
      valid
    end

    def import
      data, _errors = open_and_decode_file(file)

      w.reset! data.size, :yellow

      data.each do |incoming_payment|
        next if incoming_payment.global_net_amount.to_d <= 0.0

        if incoming_payment.cash_amount&.to_d != 0.0
          mode = :cash
          amount = incoming_payment.cash_amount.to_d
        elsif incoming_payment.other_mode&.downcase == 'chèque' && incoming_payment.other_amount&.to_d != 0.0
          mode = :cheque
          amount = incoming_payment.other_amount.to_d
        elsif incoming_payment.other_amount&.to_d != 0.0
          mode = :card
          amount = incoming_payment.other_amount.to_d
        elsif incoming_payment.cb_amount&.to_d != 0.0
          mode = :card
          amount = incoming_payment.cb_amount.to_d
        else
          w.error "No mode found for #{incoming_payment.payment_number}"
        end

        payment_mode = find_payment_mode(mode)
        ip = find_or_create_incoming_payment(incoming_payment, payment_mode, amount)
        attach_sale(ip, incoming_payment.transaction_number)

        w.check_point
      end
    end

    def find_payment_mode(mode)
      Maybe(find_payment_mode_by_provider(mode))
        .or_raise("No payment mode setup for #{mode}. Contact the support to setup this exchanger")
    end

    # @return [IncomingPaymentMode, nil]
    def find_payment_mode_by_provider(mode)
      unwrap_one('incoming_payment') { IncomingPaymentMode.of_provider_name(self.class.vendor, provider_name).of_provider_data(:reference_number, mode.to_s) }
    end

    # @param [OpenStruct] incoming_payment_info
    # @param [IncomingPaymentMode] payment_mode
    # @return [IncomingPayment]
    def find_or_create_incoming_payment(incoming_payment_info, payment_mode, amount)
      Maybe(find_incoming_payment_by_provider(incoming_payment_info.payment_number))
        .recover { create_incoming_payment(incoming_payment_info, incoming_payment_info.payment_number, payment_mode, amount) }
        .or_raise
    end

    #  @param [String] reference_number
    # @return [IncomingPayment, nil]
    def find_incoming_payment_by_provider(payment_number)
      unwrap_one('incoming payment') do
        IncomingPayment.of_provider_name(self.class.vendor, :incoming_payments)
                       .of_provider_data(:incoming_payment_reference_number, payment_number)
      end
    end

    # @param [OpenStruct] incoming_payment_info
    # @param [String] reference_number
    # @param [IncomingPaymentMode] payment_mode
    # @return [IncomingPayment]
    def create_incoming_payment(incoming_payment_info, payment_number, payment_mode, amount)

      # entity is link_to pos_name
      entity = find_or_create_entity(incoming_payment_info.pos_name)

      invoiced_at = to_invoiced_at(incoming_payment_info.invoiced_on, incoming_payment_info.invoiced_hour)

      IncomingPayment.create!(
        mode: payment_mode,
        paid_at: invoiced_at,
        to_bank_at: invoiced_at,
        amount: amount,
        payer: entity,
        received: true,
        provider: provider_value(incoming_payment_reference_number: payment_number)
      )
    end

    def attach_sale(payment, sale_reference_number)
      sale = Sale.of_provider_name(self.class.vendor, :sales).of_provider_data(:sale_reference_number, sale_reference_number).first
      sale.affair.attach(payment) if payment && sale && sale.affair
    end

    def provider_name
      :incoming_payments
    end

    def open_and_decode_file(file)
      # Open and Decode: CSVReader::read(file)
      rows = ActiveExchanger::CsvReader.new(col_sep: "\t").read(file)
      parser = ActiveExchanger::CsvParser.new(NORMALIZATION_CONFIG)

      parser.normalize(rows)
    end
  end
end
