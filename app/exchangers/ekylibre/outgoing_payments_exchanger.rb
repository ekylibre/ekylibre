class Ekylibre::OutgoingPaymentsExchanger < ActiveExchanger::Base
  def import
    rows = CSV.read(file, headers: true).delete_if { |r| r[2].blank? }
    w.count = rows.size
    now = Time.now

    # find a responsible
    responsible = User.employees.first

    rows.each_with_index do |row, index|
      line_index = index + 2
      r = {
        invoiced_at:        (row[0].blank? ? nil : Date.parse(row[0].to_s)),
        payee_full_name:    (row[1].blank? ? nil : row[1]),
        reference_number:   (row[2].blank? ? nil : row[2].upcase),
        outgoing_payment_mode_name: (row[3].blank? ? nil : row[3].to_s),
        amount: (row[4].blank? ? nil : row[4].gsub(',', '.').to_d),
        paid_on: (row[5].blank? ? nil : Date.parse(row[5].to_s)),
        # Extra infos
        document_reference_number: "#{Date.parse(row[0].to_s)}_#{row[1]}_#{row[2].upcase}".gsub(' ', '-'),
        description: now.l
      }.to_struct

      # set paid_at
      if r.paid_on
        paid_at = r.paid_on.to_datetime
      elsif r.invoiced_at
        paid_at = r.invoiced_at
      end

      # find an outgoing payment mode
      unless payment_mode = OutgoingPaymentMode.where(name: r.outgoing_payment_mode_name).first
        fail ActiveExchanger::InvalidDataError, "Cannot find outgoing payment mode #{r.outgoing_payment_mode_name} at line #{line_index}"
      end

      # find an entity
      unless entity = Entity.where('full_name ILIKE ?', r.payee_full_name).first || Entity.where('last_name ILIKE ?', r.payee_full_name).first
        # raise ActiveExchanger::InvalidDataError, "Cannot find supplier #{r.payee_full_name} at line #{line_index}"
        entity = Entity.create!(last_name: r.payee_full_name)
      end

      # find or create an outgoing payment
      if payment_mode && r.amount && paid_at && entity && responsible
        unless outgoing_payment = OutgoingPayment.where(payee: entity, paid_at: paid_at, mode: payment_mode, amount: r.amount).first
          outgoing_payment = OutgoingPayment.create!(mode: payment_mode,
                                                     paid_at: paid_at,
                                                     to_bank_at: paid_at,
                                                     amount: r.amount,
                                                     payee: entity,
                                                     responsible: responsible
                                                    )
        end
      end

      # find an affair througt purchase and link affair and payment
      if r.reference_number && entity && outgoing_payment
        # see if purchase exist anyway
        if purchase = Purchase.where(supplier_id: entity.id, invoiced_at: r.invoiced_at, reference_number: r.reference_number).first
          purchase.affair.attach(outgoing_payment) if purchase.affair
        end
      end

      w.check_point
    end
  end
end
