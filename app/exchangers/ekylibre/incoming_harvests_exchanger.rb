# frozen_string_literal: true

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
  class IncomingHarvestsExchanger < ActiveExchanger::Base
    category :plant_farming
    vendor :ekylibre

    def import_resource
      @import_resource ||= Import.find(options[:import_id])
    end

    def check
      rows = CSV.read(file, col_sep: ';', headers: true).delete_if { |r| r[0].blank? }
      valid = true
      now = Time.zone.now
      w.count = rows.size

      rows.each_with_index do |row, index|
        line_number = index + 2
        r = {
          received_at:        (row[1].blank? || row[2].blank? ? nil : Time.strptime(Date.parse(row[1].to_s).strftime('%d/%m/%Y') + ' ' + row[2].to_s, '%d/%m/%Y %H:%M')),
          ticket_number:    (row[0].blank? ? nil : row[0].to_s),
          support_codes: (row[3].blank? ? nil : row[3].to_s.strip.upcase.split(/\s*\,\s*/)),
          worker_code: (row[4].blank? ? nil : row[4].to_s),
          tractor_code: (row[5].blank? ? nil : row[5].to_s),
          trailer_code: (row[6].blank? ? nil : row[6].to_s),
          quantity: (row[7].blank? ? nil : row[7].tr(',', '.').to_d),
          unit: (row[8].blank? ? nil : row[8].to_s),
          storage_code: (row[9].blank? ? nil : row[9].to_s)
        }.to_struct

        # Check date
        if r.received_at
          w.info " Date : #{r.received_at} "
        else
          w.warn 'No date given'
          valid = false
        end

        if r.ticket_number
          w.info " ticket_number : #{r.ticket_number} "
        else
          w.warn 'No ticket_number given'
          valid = false
        end

        if r.support_codes.any?
          w.info " Support : #{r.support_codes} "
        else
          w.warn 'No support_codes given'
          valid = false
        end
      end
      valid
    end

    def import
      rows = CSV.read(file, col_sep: ';', headers: true)
      w.count = rows.size
      now = Time.zone.now

      rows.each_with_index do |row, index|
        line_number = index + 2
        w.check_point && next if row[0].blank?

        r = {
          received_at:        (row[1].blank? || row[2].blank? ? nil : Time.strptime(Date.parse(row[1].to_s).strftime('%d/%m/%Y') + ' ' + row[2].to_s, '%d/%m/%Y %H:%M')),
          ticket_number:    (row[0].blank? ? nil : row[0].to_s),
          support_codes: (row[3].blank? ? nil : row[3].to_s.strip.upcase.split(/\s*\,\s*/)),
          worker_code: (row[4].blank? ? nil : row[4].to_s),
          tractor_code: (row[5].blank? ? nil : row[5].to_s),
          trailer_code: (row[6].blank? ? nil : row[6].to_s),
          quantity: (row[7].blank? ? nil : row[7].tr(',', '.').to_d),
          unit: (row[8].blank? ? nil : row[8].to_s),
          storage_code: (row[9].blank? ? nil : row[9].to_s)
        }.to_struct

        product_measure = Measure.new(r.quantity, r.unit)
        # create incoming harvest
        unless IncomingHarvest.find_by(ticket_number: r.ticket_number)
          ih = IncomingHarvest.new(received_at: r.received_at,
                                   ticket_number: r.ticket_number,
                                       quantity: product_measure,
                                       trailer_id: (r.trailer_code.present? ? Product.find_by(work_number: r.trailer_code)&.id : nil),
                                       tractor_id: (r.tractor_code.present? ? Product.find_by(work_number: r.tractor_code)&.id : nil))
          ih.driver_id = Product.find_by(work_number: r.worker_code)&.id if r.worker_code.present?
          ih.storages.new(storage_id: Product.find_by(work_number: r.storage_code)&.id, quantity: product_measure) if r.storage_code.present?
          r.support_codes.each do |support_code|
            s_code = support_code.split(/\s*\:\s*/).first
            s_percentage = support_code.split(/\s*\:\s*/).last&.tr(',', '.')&.to_d
            s_percentage = 100.0 if s_percentage == 0.0
            crop = find_crop(s_code, r.received_at)
            ih.crops.new(harvest_percentage_repartition: s_percentage, crop_id: crop.id) if crop.present?
          end
          ih.save!
        end
        w.check_point
      end
    end

    def find_crop(code, at)
      return nil unless (code.present? && at.present?)

      if cz = CultivableZone.find_by(work_number: code)
        ap = ActivityProduction.of_campaign(Campaign.on(at.to_date)).where(cultivable_zone: cz)
        if ap.any?
          Product.where(activity_production_id: ap.pluck(:id)).first
        else
          nil
        end
      elsif LandParcel.find_by(work_number: code)
        LandParcel.find_by(work_number: code)
      elsif Plant.find_by(work_number: code)
        Plant.find_by(work_number: code)
      else
        nil
      end
    end

  end
end
