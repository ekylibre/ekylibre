module Ekylibre
  class CashTransfersExchanger < ActiveExchanger::Base
    # Create cash_transfert between internal accounts
    def import
      rows = CSV.read(file, headers: true).delete_if { |r| r[0].blank? }
      w.count = rows.size

      rows.each do |row|
        r = {
          started_on: row[0].blank? ? nil : Date.parse(row[0].to_s),
          sender_account_name: row[1].blank? ? nil : row[1].to_s,
          receiver_account_name: row[2].blank? ? nil : row[2].to_s,
          amount: row[3].blank? ? nil : row[3].tr(',', '.').to_d
        }.to_struct

        unless r.started_on
          w.error "Need a valid date for #{r.started_on}"
          next
        end

        # find emission cash by name or bank name or iban
        emission_cash = Cash.where('name ILIKE ?', r.sender_account_name).first
        emission_cash ||= Cash.where('bank_name ILIKE ?', r.sender_account_name).first
        emission_cash ||= Cash.find_by(iban: r.sender_account_name)

        unless emission_cash
          w.error "Need a valid emission_cash for #{r.sender_account_name}"
          next
        end

        # find reception cash by name or bank name or iban
        reception_cash = Cash.where('name ILIKE ?', r.receiver_account_name).first
        reception_cash ||= Cash.where('bank_name ILIKE ?', r.receiver_account_name).first
        reception_cash ||= Cash.find_by(iban: r.receiver_account_name)

        unless reception_cash
          w.error "Need a valid reception_cash for #{r.receiver_account_name}"
          next
        end

        # check if cash_transfer already exist
        unless cash_transfer = CashTransfer.find_by(emission_amount: r.amount,
                                                    emission_cash_id: emission_cash.id,
                                                    reception_cash_id: reception_cash.id,
                                                    transfered_at: r.started_on.to_time)
          CashTransfer.create!(
                        emission_amount: r.amount,
                        emission_cash_id: emission_cash.id,
                        reception_cash_id: reception_cash.id,
                        transfered_at: r.started_on.to_time)
        end

        w.check_point
      end
    end
  end
end
