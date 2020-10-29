class RenameFrenchTaxesNames < ActiveRecord::Migration
  CHANGES = {
    french_vat_eu: { name: 'TVA intra-communautaire' },
    french_vat_import_export: { name: 'TVA import/export' },
    french_vat_intermediate_2012: { name: 'TVA 7.0 % (2012)' },
    french_vat_intermediate_2014: { name: 'TVA 10.0 %' },
    french_vat_normal_1966: { name: 'TVA 17.6 % (1966)' },
    french_vat_normal_1982: { name: 'TVA 18.6 % (1982)' },
    french_vat_normal_1995: { name: 'TVA 20.6 % (1995)' },
    french_vat_normal_2000: { name: 'TVA 19.6 % (2000)' },
    french_vat_normal_2014: { name: 'TVA 20.0 %' },
    french_vat_null: { name: 'TVA non-applicable' },
    french_vat_null: { name: 'TVA non-applicable' },
    french_vat_particular_1982: { name: 'TVA 5.5 % (1982)' },
    french_vat_particular_1989: { name: 'TVA 2.1 %' },
    french_vat_reduced: { name: 'TVA 5.5 %' }
  }.freeze
  def change
    reversible do |dir|
      dir.up do
        CHANGES.each do |reference_name, attributes|
          execute <<-SQL
          UPDATE
            taxes AS t
            SET name = '#{attributes[:name]}'
            WHERE t.reference_name = '#{reference_name}'
          SQL
        end
      end
    end
  end
end
