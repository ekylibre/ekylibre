class AddAttachmentImportFileToFinancialYearExchanges < ActiveRecord::Migration
  def self.up
    change_table :financial_year_exchanges do |t|
      t.attachment :import_file
    end
  end

  def self.down
    remove_attachment :financial_year_exchanges, :import_file
  end
end
