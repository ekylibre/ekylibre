module Ekylibre
  # Imports incoming payment in CSV format (with commas in UTF-8)
  # Columns are:
  #  - A: date of invoice associated to incoming payment
  #  - B: payer full name
  #  - C: number
  #  - D: code of payment mode
  #  - E: amount
  #  - F: paid on
  #  - G: reference of document in DMS (optional)
  #  - H: description (optional)
  class IncomingPaymentsExchanger < ActiveExchanger::Base
    def check
      rows = CSV.read(file, headers: true).delete_if { |r| r[0].blank? }
      valid = true
      now = Time.zone.now
      w.count = rows.size

      # find a responsible
      responsible = User.employees.first
      unless responsible
        w.error 'No responsible found'
        valid = false
      end

      rows.each_with_index do |row, index|
        line_number = index + 2
        prompt = "L#{line_number.to_s.yellow}"
        r = {
          invoiced_at:        (row[0].blank? ? nil : Date.parse(row[0].to_s)),
          payer_full_name:    (row[1].blank? ? nil : row[1]),
          reference_number:   (row[2].blank? ? nil : row[2].upcase),
          incoming_payment_mode_name: (row[3].blank? ? nil : row[3].to_s),
          amount: (row[4].blank? ? nil : row[4].tr(',', '.').to_d),
          paid_on: (row[5].blank? ? nil : Date.parse(row[5])),
          # Extra infos
          document_reference_number: "#{Date.parse(row[0].to_s)}_#{row[1]}_#{row[2].upcase}".tr(' ', '-'),
          description: now.l
        }.to_struct

        # Check date
        paid_at = nil
        if r.paid_on
          paid_at = r.paid_on.to_datetime
          w.info " Date : #{r.paid_on} "
        elsif r.invoiced_at
          paid_at = r.invoiced_at
          w.info " Date : #{r.invoiced_at} "
        else
          w.warn 'No date given'
          valid = false
        end

        # Check outgoing payment mode
        payment_mode = IncomingPaymentMode.find_or_create_by(name: r.incoming_payment_mode_name)
        unless payment_mode
          w.error "Cannot find incoming payment mode #{r.incoming_payment_mode_name} at line #{line_number.to_s.yellow}"
          valid = false
        end

        # Check an entity presence
        entity = Entity.find_by('full_name ILIKE ?', r.payer_full_name) ||
                 Entity.find_by('last_name ILIKE ?', r.payer_full_name)
        unless entity
          w.info " Entity will be created with #{r.payer_full_name} "
        end

        # Check Outgoing payment presence
        incoming_payment = IncomingPayment.find_by(payer: entity, paid_at: paid_at, mode: payment_mode, amount: r.amount)
        if incoming_payment
          w.info " Outgoing payment is already present with ID : #{outgoing_payment.id} "
        end

        # Check affair presence
        next unless r.reference_number && entity
        sale = Sale.find_by(client_id: entity.id, invoiced_at: r.invoiced_at, reference_number: r.reference_number)
        if sale
          w.info "Sale found with ID : #{sale.id}"
        else
          w.warn 'No sale found. Incoming payment will be in stand-by'
        end
      end
      valid
    end

    def import
      rows = CSV.read(file, headers: true)
      w.count = rows.size
      now = Time.zone.now

      # find an responsible
      responsible = User.employees.first

      rows.each_with_index do |row, index|
        line_number = index + 2
        w.check_point && next if row[0].blank?
        r = {
          invoiced_at:        (row[0].blank? ? nil : Date.parse(row[0].to_s)),
          payer_full_name:    (row[1].blank? ? nil : row[1]),
          reference_number:   (row[2].blank? ? nil : row[2].upcase),
          incoming_payment_mode_name: (row[3].blank? ? nil : row[3].to_s),
          amount: (row[4].blank? ? nil : row[4].tr(',', '.').to_d),
          paid_on: (row[5].blank? ? nil : Date.parse(row[5])),
          # Extra infos
          document_reference_number: "#{Date.parse(row[0].to_s)}_#{row[1]}_#{row[2].upcase}".tr(' ', '-'),
          description: now.l
        }.to_struct

        # set paid_at
        if r.paid_on
          paid_at = r.paid_on.to_datetime
        elsif r.invoiced_at
          paid_at = r.invoiced_at
        end

        # find an incoming payment mode
        payment_mode = IncomingPaymentMode.find_by(name: r.incoming_payment_mode_name)
        unless payment_mode
          raise ActiveExchanger::InvalidDataError, "Cannot find incoming payment mode #{r.incoming_payment_mode_name} at line #{line_number}"
        end

        # find an entity
        if r.payer_full_name
          entity = Entity.where('full_name ILIKE ?', r.payer_full_name).first
        end

        # find or create an outgoing payment
        if r.amount && paid_at && entity && responsible
          incoming_payment = IncomingPayment.find_by(
            payer: entity,
            paid_at: paid_at,
            mode: payment_mode,
            amount: r.amount
          )
          unless incoming_payment
            incoming_payment = IncomingPayment.create!(
              mode: payment_mode,
              paid_at: paid_at,
              to_bank_at: paid_at,
              amount: r.amount,
              payer: entity,
              received: true,
              responsible: responsible
            )
          end
        end

        # find an affair througt purchase and link affair and payment
        if r.reference_number && entity && incoming_payment
          # see if purchase exist anyway
          sale = Sale.find_by(
            client_id: entity.id,
            invoiced_at: r.invoiced_at,
            reference_number: r.reference_number
          )
          sale.affair.attach(incoming_payment) if sale && sale.affair
        end

        w.check_point
      end
    end
  end
end
