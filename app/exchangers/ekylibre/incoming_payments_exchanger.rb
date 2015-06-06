class Ekylibre::IncomingPaymentsExchanger < ActiveExchanger::Base

  def import
    rows = CSV.read(file, headers: true).delete_if{|r| r[0].blank?}
    w.count = rows.size

    # find an responsible
    responsible = User.employees.first

    rows.each do |row|
      next if row[2].blank?
      r = {
        document_reference_number: (row[0].blank? ? nil : row[0].to_s),
        incoming_payment_mode_name: (row[1].blank? ? nil : row[1].to_s),
        amount: (row[2].blank? ? nil : row[2].gsub(",", ".").to_d),
        paid_on: (row[3].blank? ? nil : row[3].to_datetime)
      }.to_struct

      # get information from document_reference_number
      # first part = purchase_invoiced_at
      # second part = entity_full_name (replace - by space)
      # third part = purchase_reference_number
      if r.document_reference_number
        arr = r.document_reference_number.strip.downcase.split('_')
        sale_invoiced_at = arr[0].to_datetime
        entity_full_name = arr[1].to_s.gsub("-", " ")
        sale_reference_number = arr[2].to_s.upcase
      end

      # set paid_at
      if r.paid_on
        paid_at = paid_on.to_datetime
      elsif sale_invoiced_at
        paid_at = sale_invoiced_at
      end

      # find an outgoing payment mode
      if r.incoming_payment_mode_name
        op_mode = IncomingPaymentMode.where(name: r.incoming_payment_mode_name).first
      end

      # find an entity
      if entity_full_name
        entity = Entity.where("full_name ILIKE ?", entity_full_name).first
      end

      # find or create an outgoing payment
      if op_mode and r.amount and paid_at and entity and responsible
        unless incoming_payment = IncomingPayment.where(payer: entity, paid_at: paid_at, mode: op_mode, amount: r.amount).first
          incoming_payment = IncomingPayment.create!(mode: op_mode,
                                                     paid_at: paid_at,
                                                     to_bank_at: paid_at,
                                                     amount: r.amount,
                                                     payer: entity,
                                                     responsible: responsible
                                                    )
        end
      end

      # find an affair througt purchase and link affair and payment
      if sale_reference_number and entity and incoming_payment
        # see if purchase exist anyway
        if sale = Sale.where(client_id: entity.id, invoiced_at: sale_invoiced_at, reference_number: sale_reference_number).first
          if sale.affair
            sale.affair.attach(incoming_payment)
          end
        end
      end

      w.check_point
    end
  end

end
