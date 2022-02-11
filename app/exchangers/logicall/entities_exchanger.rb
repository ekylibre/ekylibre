# frozen_string_literal: true

module Logicall
  class EntitiesExchanger < ActiveExchanger::Base
    category :sales
    vendor :logicall

    COUNTRY_TRANSCODE = { 'ALLEMAGNE' => :de,
                          'BELGIQUE' => :be,
                          'DANEMARK' => :dk,
                          'ESTONIE' => :ee,
                          'FRANCE' => :fr,
                          'FRANCE CONGE' => :fr,
                          'LUXEMBOURG' => :lu,
                          'NORWAY' =>:no,
                          'SUISSE' => :ch }.freeze

    CUSTOM_FIELDS = {
                      family: 'Famille',
                      intermediate: 'Intermédiaire',
                      locutor: 'Interlocuteur',
                      search_key: 'Clef de recherche'
                    }.freeze

    NORMALIZATION_CONFIG = [
      { col: 0, name: :client_number, type: :string },
      { col: 1, name: :search_key, type: :string },
      { col: 2, name: :client_name, type: :string },
      { col: 3, name: :town, type: :string },
      { col: 4, name: :vat_number, type: :string },
      { col: 5, name: :phone_number, type: :string },
      { col: 6, name: :mobile_number, type: :string },
      { col: 7, name: :fax_number, type: :string },
      { col: 8, name: :email, type: :string },
      { col: 9, name: :address_line_1, type: :string },
      { col: 10, name: :address_line_2, type: :string },
      { col: 11, name: :postal_code, type: :string },
      { col: 12, name: :country, type: :string },
      { col: 13, name: :family, type: :string },
      { col: 14, name: :intermediate, type: :string },
      { col: 16, name: :locutor, type: :string }
    ].freeze

    def check
      rows, errors = parse_file(file)
      w.count = rows.size

      valid = errors.all?(&:empty?)
      if valid == false
        w.error "The file is invalid: #{errors}"
        return false
      end
      valid
    end

    def import
      rows, errors = parse_file(file)
      w.count = rows.size
      country_preference = Preference[:country]

      custom_fields = create_custom_fields

      rows.each_with_index do |row, index|
        w.info "Line #{index + 2} | #{row.client_number} -----------------------------------------"
        entity = Entity.of_provider_vendor(self.class.vendor).of_provider_data(:entity_code, row.client_number&.strip)
        next if entity.present?

        acc = Account.where('name LIKE ?', "%#{row.client_number&.strip}%").first
        acc ||= Account.where('name LIKE ?', "%#{row.client_name&.strip}%").first

        cy = COUNTRY_TRANSCODE[row.country]
        cy ||= :fr

        entity = Entity.create!(
          active: true,
          client: true,
          client_account: (acc.present? ? acc : nil),
          number: row.client_number&.strip,
          first_name: nil,
          last_name: row.client_name&.strip,
          full_name: row.client_name&.strip,
          country: cy.to_s,
          nature: :organization,
          provider: provider_value(entity_code: row.client_number&.strip)
        )

        custom_fields.each do |k|
          val = row.send(k.column_name).to_s.strip
          w.info "#{k.name} values : #{val}"
          if val.present?
            entity.set_custom_value(k, val)
            entity.save!
            w.info "Entity customs fields : #{entity.custom_fields}"
          end
        end

        # Add mail address if given
        postal_code_city = ''
        postal_code_city += row.postal_code.strip + ' ' if row.postal_code
        postal_code_city += row.town&.strip if row.town

        mail_attributes = {}
        mail_attributes.store(:by_default, true)
        mail_attributes.store(:mail_line_1, row.client_name&.strip) if row.client_name
        mail_attributes.store(:mail_line_4, row.address_line_1&.strip) if row.address_line_1
        mail_attributes.store(:mail_line_5, row.address_line_2&.strip) if row.address_line_2
        mail_attributes.store(:mail_line_6, postal_code_city) if postal_code_city.present?
        mail_attributes.store(:mail_country, cy.to_s)
        unless postal_code_city.blank? || entity.mails.where('mail_line_6 ILIKE ?', postal_code_city).where(mail_country: cy.to_s).any?
          w.info "Address : #{mail_attributes}"
          entity.mails.create!(mail_attributes)
        end

        # Add phone number if given
        unless row.phone_number.blank? || entity.phones.where(coordinate: row.phone_number&.strip).any?
          w.info "Phone : #{row.phone_number.strip}"
          entity.phones.create!(coordinate: row.phone_number.strip)
        end

        # Add mobile number if given
        unless row.mobile_number.blank? || entity.mobiles.where(coordinate: row.mobile_number&.strip).any?
          w.info "Mobile : #{row.mobile_number.strip}"
          entity.mobiles.create!(coordinate: row.mobile_number.strip)
        end

        # Add fax phone number if given
        unless row.fax_number.blank? || entity.faxes.where(coordinate: row.fax_number&.strip).any?
          w.info "Fax number : #{row.fax_number&.strip}"
          entity.faxes.create!(coordinate: row.fax_number.strip)
        end

        # Add email if given
        unless row.email.blank?
          w.info "Email : #{row.email.strip}"
          clean_email = I18n.transliterate(row.email.strip)
          w.info "Clean email : #{clean_email}"
          entity.emails.create!(coordinate: clean_email)
        end

        w.check_point
      end
    end

    private

      def create_custom_fields
        a = []
        CUSTOM_FIELDS.each do |k, v|
          # create custom field if not exist
          if cf = CustomField.find_by(column_name: k.to_s, customized_type: 'Entity')
            a << cf
          else
            # create custom field
            a << CustomField.create!(name: v, customized_type: 'Entity',
                                     nature: 'text',
                                     active: true,
                                     required: false,
                                     column_name: k.to_s)
          end
        end
        a.compact
      end

    protected

      # @return [Import]
      def import_resource
        @import_resource ||= Import.find(options[:import_id])
      end

      def provider_value(**data)
        { vendor: self.class.vendor, name: provider_name, id: import_resource.id, data: data }
      end

      def provider_name
        :entities
      end

      def parse_file(file)
        rows = ActiveExchanger::CsvReader.new(col_sep: ',').read(file)
        parser = ActiveExchanger::CsvParser.new(NORMALIZATION_CONFIG)

        parser.normalize(rows)
      end
  end
end
