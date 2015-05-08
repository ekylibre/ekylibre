class Ekylibre::OutgoingPaymentsExchanger < ActiveExchanger::Base

  def import
    rows = CSV.read(file, headers: true).delete_if{|r| r[0].blank?}
    w.count = rows.size

    # find an responsible
    responsible = User.employees.first

    rows.each do |row|
      next if row[2].blank?
      r = {
        document_reference_number: (row[0].blank? ? nil : row[0].to_s),
        outgoing_payment_mode_name: (row[1].blank? ? nil : row[1].to_s),
        amount: (row[2].blank? ? nil : row[2].gsub(",", ".").to_d),
        paid_on: (row[3].blank? ? nil : row[3].to_datetime)
      }.to_struct

      # get information from document_reference_number
      # first part = purchase_invoiced_at
      # second part = entity_full_name (replace - by space)
      # third part = purchase_reference_number
      if r.document_reference_number
        arr = r.document_reference_number.strip.downcase.split('_')
        purchase_invoiced_at = arr[0].to_datetime
        entity_full_name = arr[1].to_s.gsub("-", " ")
        purchase_reference_number = arr[2].to_s.upcase
      end

      # set paid_at
      if r.paid_on
        paid_at = paid_on.to_datetime
      elsif purchase_invoiced_at
        paid_at = purchase_invoiced_at
      end

      # find an outgoing payment mode
      if r.outgoing_payment_mode_name
        op_mode = OutgoingPaymentMode.where(name: r.outgoing_payment_mode_name).first
      end

      # find an entity
      if entity_full_name
        entity = Entity.where("full_name ILIKE ?", entity_full_name).first
      end

      # find or create an outgoing payment
      if op_mode and r.amount and paid_at and entity and responsible
        unless outgoing_payment = OutgoingPayment.where(payee: entity, paid_at: paid_at, mode: op_mode, amount: r.amount).first
          outgoing_payment = OutgoingPayment.create!(mode: op_mode,
                                                     paid_at: paid_at,
                                                     to_bank_at: paid_at,
                                                     amount: r.amount,
                                                     payee: entity,
                                                     responsible: responsible
                                                    )
        end
      end

      # find an affair througt purchase and link affair and payment
      if purchase_reference_number and entity and outgoing_payment
        # see if purchase exist anyway
        if purchase = Purchase.where(supplier_id: entity.id, invoiced_at: purchase_invoiced_at, reference_number: purchase_reference_number).first
          if purchase.affair
            purchase.affair.attach(outgoing_payment)
          end
        end
      end

      w.check_point
    end
  end

end
