# coding: utf-8
module FermesLarrere
  # Imports incoming payment in CSV format (with commas in UTF-8)
  # Columns are:
  #  - A: payment number
  #  - B: sale number
  #  - C: amount
  #  - D: paid on
  #  - E: incoming payment mode id
  #  - F: client code
  class IncomingPaymentsExchanger < ActiveExchanger::Base
    DEFAULT_MODE_ID = 3         # ???
    DEFAULT_RESPONSIBLE_ID = 13 # Isabelle Larrère

    def import
      rows = Roo::Excelx.new(file)
      w.count = rows.count

      previous_number_incoming_payment = nil

      global_amount = []
      invoice_origin_reference_numbers = []

      # find an responsible
      responsible = User.find_by(id: DEFAULT_RESPONSIBLE_ID)

      # set others variables
      amount = nil
      paid_at = nil
      payment_mode = nil
      last_incoming_payment_origin_reference_number = nil
      last_client_code = nil

      rows.each_row_streaming(offset: 1, pad_cells: true) do |row|
        r = parse_row(row)
        next if row.empty?

        current_number_incoming_payment = r.incoming_payment_origin_reference_number
        previous_number_incoming_payment ||= current_number_incoming_payment

        w.info "LINE REFERENCE : #{r.incoming_payment_origin_reference_number} - #{r.invoice_origin_reference_number}".yellow

        # If we start a new incoming_payment, we close the previous one
        if current_number_incoming_payment != previous_number_incoming_payment

          # call method to create payment and link sales
          create_payment_and_link_sales(amount, paid_at, invoice_origin_reference_numbers, previous_number_incoming_payment, responsible, payment_mode, last_client_code)

          # reset global amount and others references
          global_amount = []
          invoice_origin_reference_numbers = []
          previous_number_incoming_payment = current_number_incoming_payment

        end

        # get incoming_payment_mode
        payment_mode = if r.incoming_payment_mode_id
                         IncomingPaymentMode.find_by(id: r.incoming_payment_mode_id)
                       else
                         IncomingPaymentMode.find_by(id: DEFAULT_MODE_ID)
                       end

        global_amount << r.amount
        amount = global_amount.compact.sum
        paid_at = r.payment_on.to_time
        unless r.invoice_origin_reference_number.blank?
          invoice_origin_reference_numbers << r.invoice_origin_reference_number
        end
        last_incoming_payment_origin_reference_number = current_number_incoming_payment
        last_client_code = r.client_origin_reference_number

        w.info "END - LINE REFERENCE: #{r.incoming_payment_origin_reference_number} - #{r.invoice_origin_reference_number}".green

        w.check_point
      end

      # Finish last incoming payment
      if amount && paid_at && invoice_origin_reference_numbers.any?
        create_payment_and_link_sales(amount, paid_at, invoice_origin_reference_numbers, last_incoming_payment_origin_reference_number, responsible, payment_mode, last_client_code)
      end
    end

    def parse_row(row)
      {
        incoming_payment_origin_reference_number: (row[0].blank? ? nil : row[0].value.to_i.to_s),
        invoice_origin_reference_number:          (row[1].blank? ? nil : row[1].value.to_i.to_s),
        amount:                                   (row[2].blank? ? nil : row[2].value.to_d),
        payment_on:                               (row[3].blank? ? nil : row[3].value),
        incoming_payment_mode_id:                 (row[4].blank? ? nil : row[4].value.to_i),
        client_origin_reference_number:           (row[5].blank? ? nil : row[5].value.to_s)
      }.to_struct
    end

    def create_payment_and_link_sales(amount, paid_at, invoice_codes, incoming_payment_origin_reference_number, responsible, payment_mode, client_code)
      sales = Sale.where('codes ->> ? IN (?)', FermesLarrere::EUROFLOW_KEY, invoice_codes).reorder(:id)
      first_sale = sales.first
      unless
        w.warn 'No sales found'.red
      end

      # find an client
      client = find_or_create_client(invoice_codes, client_code)

      # find or create an outgoing payment
      if amount && paid_at && responsible
        incoming_payment = IncomingPayment.where('codes ->> ? = ?', FermesLarrere::EUROFLOW_KEY, incoming_payment_origin_reference_number).first
        unless incoming_payment
          incoming_payment = IncomingPayment.new(
            codes: {
              FermesLarrere::EUROFLOW_KEY => incoming_payment_origin_reference_number
            }
          )
          w.info 'New incoming payment'.green
        end
        if incoming_payment.new_record? || incoming_payment.updateable?
          incoming_payment.attributes = {
            mode: payment_mode,
            paid_at: paid_at,
            to_bank_at: paid_at,
            amount: amount,
            payer: client,
            received: true,
            responsible: responsible
          }
          incoming_payment.save!
        end
        if incoming_payment
          w.info 'Incoming payment found and updated'.green
        else
          w.warn 'Incoming payment not found'.red
        end
      else
        w.warn 'Incoming payment cannot be searched'.red
      end

      if first_sale && incoming_payment
        # find affair from first sale
        affair = first_sale.affair
        # attach payment
        affair.attach(incoming_payment)

        invoice_codes.each do |sale_number|
          # find a sale
          sale = Sale.where('codes ->> ? = ?', FermesLarrere::EUROFLOW_KEY, sale_number.to_s).first
          next unless sale && sale.client_id == affair.third_id
          # TODO: only attach if not already attached by the same payment
          w.info "Begins to attach #{sale.number}...".yellow
          start = Time.zone.now
          # sale.affair.attach(incoming_payment) if sale.affair
          affair.attach(sale)
          d = Time.zone.now - start
          w.info "Attached payment in #{d.seconds}".green
        end
      else
        w.warn 'Cannot attach incoming_payment to sales'.red
      end
    end

    def find_or_create_client(invoice_codes, client_code = nil)
      entity = nil
      if !entity && invoice_codes.any?
        client_ids = Sale.where('codes ->> ? IN (?)', FermesLarrere::EUROFLOW_KEY, invoice_codes).pluck(:client_id).uniq
        entity = Entity.find_by(id: client_ids.first) if client_ids.size == 1 # Not too much doubt
        w.info 'Entity found via first sale'.green if entity
      end
      if !entity && client_code.present?
        entity = Entity.where('codes ->> ? = ?', FermesLarrere::EUROFLOW_KEY, client_code).first
        unless entity
          entity = Entity.new
          entity.nature = :organization
          entity.codes = { FermesLarrere::EUROFLOW_KEY => client_code }
          entity.active = true
          entity.client = true
          entity.last_name = client_code
          entity.save!
          w.info 'New entity'.green
        end
        w.info 'Entity found via client code'.green if entity
      end
      unless entity
        w.warn "Entity not found via client code or first sale: #{client_code.inspect} doesn't exist and #{invoice_codes.join(', ')} invoices too".red
      end
      entity
    end
  end
end
