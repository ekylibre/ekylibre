class MigrateOutgoingPaymentListDocumentNatureChangeCheckLetterName < ActiveRecord::Migration[5.0]
  
  CHECK_LETTER_NAME = 'Lot de décaissement : Lettre(s)-chèque(s)'

  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE document_templates
          SET name = '#{CHECK_LETTER_NAME}'
          WHERE nature = 'outgoing_payment_list__check_letter';
        SQL
      end
    end
  end
end
