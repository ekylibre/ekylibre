# frozen_string_literal: true

class MigrateOutgoingPaymentListDocumentNature < ActiveRecord::Migration[4.2]
  CHECK_LETTER_NAME = 'Lot de décaissement : Lettre chèque'
  STANDARD_NAME = 'Lot de décaissement'

  # This migration normalies the state of the document_templates related to outgoing_payment_list:
  # - There a now two ODT templates
  # - Export through JAPER is still supported but only as custom export
  def change
    reversible do |dir|
      dir.up do
        templates = execute <<~SQL
          SELECT id FROM document_templates WHERE nature = 'outgoing_payment_list'
        SQL

        if templates.count.positive?
          # We have templates for outgoing_payment_list, change teir nature to one from the new ones.
          # The only ones in the database as of 2020-09-25 are check letters
          execute <<~SQL
            UPDATE document_templates
            SET nature = 'outgoing_payment_list__check_letter',
                name = '#{CHECK_LETTER_NAME}'
            WHERE nature = 'outgoing_payment_list';
          SQL

          # Change the existing template extension to ODT
          execute <<~SQL
            UPDATE document_templates
            SET file_extension = 'odt'
            WHERE id = (SELECT id FROM document_templates WHERE nature = 'outgoing_payment_list__check_letter' AND managed = 't');
          SQL

          # Add the standard template
          create_standard_template
        else
          # No template for outgoing_payment_list in database, create both of them
          create_check_letter_template
          create_standard_template
        end
      end
    end
  end

  private

    def create_standard_template
      insert_template(
        name: STANDARD_NAME,
        default: true,
        nature: 'outgoing_payment_list__standard'
      )
    end

    def create_check_letter_template
      insert_template(
        name: CHECK_LETTER_NAME,
        default: true,
        nature: 'outgoing_payment_list__check_letter'
      )
    end

    def insert_template(name:, default:, nature:)
      execute <<~SQL
        INSERT INTO document_templates (name, active, by_default, nature, language, archiving, managed, created_at, updated_at, file_extension)
        VALUES ('#{name}', 't', '#{default ? 't' : 'f'}', '#{nature}', 'fra', 'last', 't', now(), now(), 'odt')
      SQL
    end
end
