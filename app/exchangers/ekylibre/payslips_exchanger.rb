# frozen_string_literal: true

module Ekylibre
  class PayslipsExchanger < ActiveExchanger::Base
    category :human_resources
    vendor :ekylibre

    self.deprecated = true

    def initialize(file, supervisor, options = {})
      super file, supervisor
      @attachments_dir = options['attachments_path']
      @attachments_dir &&= Pathname.new(@attachments_dir)
    end

    def check
      rows = CSV.read(file, headers: true)
      w.count = rows.size
      now = Time.zone.now
      valid = true

      vinfos = 9 - 1

      rows.each_with_index do |row, index|
        line_number = index + 2
        prompt = "L#{line_number.to_s.yellow}"

        r = {
          started_on:        (row[0].blank? ? nil : Date.parse(row[0].to_s)),
          stopped_on:        (row[1].blank? ? nil : Date.parse(row[1].to_s)),
          employee_full_name: (row[2].blank? ? nil : row[2].to_s.strip),
          reference_number:   (row[3].blank? ? nil : row[3].to_s.strip),
          amount: (row[4].blank? ? nil : row[4].tr(',', '.').to_d)
        }.to_struct

        # Check date
        unless r.started_on
          w.error "No date given at #{prompt}"
          valid = false
        end

        unless r.stopped_on
          w.error "No date given at #{prompt}"
          valid = false
        end

        unless r.amount
          w.error "No date given at #{prompt}"
          valid = false
        end

        # Check employee
        unless employee = Entity.where('full_name ILIKE ?', r.employee_full_name).first
          w.error "Cannot find supplier #{r.employee_full_name} at #{prompt}"
          valid = false
        end
      end
      valid
    end

    def import
      rows = CSV.read(file, headers: true)
      w.count = rows.size
      now = Time.zone.now

      vinfos = 9 - 1

      rows.each_with_index do |row, index|
        line_index = index + 2

        r = {
          started_on:        (row[0].blank? ? nil : Date.parse(row[0].to_s)),
          stopped_on:        (row[1].blank? ? nil : Date.parse(row[1].to_s)),
          employee_full_name: (row[2].blank? ? nil : row[2].to_s.strip),
          reference_number:   (row[3].blank? ? nil : row[3].to_s.strip),
          amount: (row[4].blank? ? nil : row[4].tr(',', '.').to_d)
        }.to_struct

        # Find or create a payslip
        # if supplier and r.invoiced_at and r.reference_number
        # see if purchase exist anyway
        unless payslip = Payslip.find_by(reference_number: r.reference_number)
          # Find supplier
          employee = Entity.where('full_name ILIKE ?', r.employee_full_name).first

          payslip = Payslip.create!(
            employee_id: employee.id,
            nature: PayslipNature.actives.first,
            started_on: r.started_on,
            stopped_on: r.stopped_on,
            emitted_on: r.stopped_on,
            reference_number: r.reference_number,
            amount: r.amount
          )
          if @attachments_dir.present? && payslip.reference_number.present?
            attachment_potential_path = @attachments_dir.join(payslip.employee.full_name.parameterize,
                                                              payslip.reference_number + ".*")
            attachment_paths = Dir.glob(attachment_potential_path)
            attachment_paths.each do |attachment_path|
              doc = Document.new(file: File.open(attachment_path))
              payslip.attachments.create!(document: doc)
            end
          end
        end

        w.check_point
      end
    end
  end
end
