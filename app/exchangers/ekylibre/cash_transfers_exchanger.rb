module Ekylibre
  class CashTransfersExchanger < ActiveExchanger::Base
    def import
      rows = CSV.read(file, headers: true)
      w.count = rows.size
      now = Time.zone.now

      rows.each_with_index do |row, index|
        line_number = index + 2
        w.check_point && next if row[0].blank?
        r = {
          invoiced_at:        (row[0].blank? ? nil : Date.parse(row[0].to_s)),
          sender_payment_mode_name: (row[1].blank? ? nil : row[1].to_s),
          receiver_payment_mode_name: (row[2].blank? ? nil : row[2].to_s),
          amount: (row[3].blank? ? nil : row[3].tr(',', '.').to_d)
        }.to_struct

        sender_payment_mode_name = IncomingPaymentMode.find_by(name: r.sender_payment_mode_name)
        unless sender_payment_mode_name
          raise ActiveExchanger::InvalidDataError, "Cannot find incoming payment mode #{r.sender_payment_mode_name} at line #{line_number}"
        end

        receiver_payment_mode_name = IncomingPaymentMode.find_by(name: r.receiver_payment_mode_name)
        unless receiver_payment_mode_name
          raise ActiveExchanger::InvalidDataError, "Cannot find incoming payment mode #{r.receiver_payment_mode_name} at line #{line_number}"
        end

        # find or create a cash transfert
        if r.invoiced_at && sender_payment_mode_name && receiver_payment_mode_name && r.amount
          cash_transfer = CashTransfer.find_by(
            transfered_at: r.invoiced_at.to_time,
            reception_cash_id: receiver_payment_mode_name.cash.id,
            emission_cash_id: sender_payment_mode_name.cash.id,
            emission_amount: r.amount

          )
          cash_transfer ||= CashTransfer.create!(
            transfered_at: r.invoiced_at.to_time,
            reception_cash_id: receiver_payment_mode_name.cash.id,
            emission_cash_id: sender_payment_mode_name.cash.id,
            currency_rate: 1.0,
            emission_amount: r.amount
          )
        end

        w.check_point
      end
    end
  end
end
