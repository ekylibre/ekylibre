class RenameTaxeNames < ActiveRecord::Migration
  CHANGES = {
    french_vat_eu: { fra_name: "TVA intra-communautaire"},
    french_vat_import_export: { fra_name: "TVA import/export"},
    french_vat_intermediate_2012: { fra_name: "TVA 7.0 % (2012)"},
    french_vat_intermediate_2014: { fra_name: "TVA 10.0 %"},
    french_vat_normal_1966: { fra_name: "TVA 17.6 % (1966)"},
    french_vat_normal_1982: { fra_name: "TVA 18.6 % (1982)"},
    french_vat_normal_1995: { fra_name: "TVA 20.6 % (1995)"},
    french_vat_normal_2000: { fra_name: "TVA 19.6 % (2000)"},
    french_vat_normal_2014: { fra_name: "TVA 20.0 %"},
    french_vat_null: { fra_name: "TVA non-applicable"},
    french_vat_null: { fra_name: "TVA non-applicable"},
    french_vat_particular_1982: { fra_name: "TVA 5.5 % (1982)"},
    french_vat_particular_1989: { fra_name: "TVA 2.1 %"},
    french_vat_reduced: { fra_name: "TVA 5.5 %"}
  }.freeze
  def change
    reversible do |dir|
      dir.up do
        CHANGES.each do |taxe_reference_name, fields|
          execute <<-SQL
          UPDATE
            taxes AS t
            SET name = '#{fields[:fra_name]}'
            WHERE t.reference_name = '#{taxe_reference_name}'
          SQL
        end
      end
    end
  end
end
