class CreateFinancialYearArchivesAndAddSignatureAndFingerprintToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :sha256_fingerprint, :string
    add_column :documents, :signature, :string

    create_table :financial_year_archives do |t|
      t.references :financial_year, null: false
      t.string     :timing, null: false
      t.string     :sha256_fingerprint, null: false
      t.string     :signature, null: false
      t.string     :path, null: false
    end
  end
end
