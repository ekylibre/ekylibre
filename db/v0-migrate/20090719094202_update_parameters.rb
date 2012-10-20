class UpdateParameters < ActiveRecord::Migration
  CONVERSIONS = {'s'=>'string', 'd'=>'decimal', 'b'=>'boolean', 'i'=>'integer', 'f'=>'record'}

  def self.up
    add_column :parameters, :record_value_id, :integer
    add_column :parameters, :record_value_type, :string
    change_column :parameters, :nature, :string, :limit=>8
    execute "UPDATE #{quoted_table_name(:parameters)} SET record_value_id=element_id, record_value_type=element_type"

    for k, v in CONVERSIONS
      execute "UPDATE #{quoted_table_name(:parameters)} SET nature='#{v}' WHERE nature='#{k}'"
    end
    
    for journal in ['sales', 'purchases', 'bank']
      execute "INSERT INTO #{quoted_table_name(:parameters)} (name, nature, record_value_type, record_value_id, company_id, created_at, updated_at) SELECT 'accountancy.default_journals.#{journal}', 'record', 'Journal', #{journal}_journal_id, id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM #{quoted_table_name(:companies)} AS companies"
    end
    execute "INSERT INTO #{quoted_table_name(:parameters)} (name, nature, record_value_type, record_value_id, company_id, created_at, updated_at) SELECT 'management.invoicing.numeration', 'record', 'Sequence', invoice_sequence_id, id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM #{quoted_table_name(:companies)} AS companies"

    remove_index :parameters, :column=>:element_id
    remove_column :parameters, :element_id
    remove_column :parameters, :element_type
    
    remove_column :companies, :sales_journal_id
    remove_column :companies, :purchases_journal_id
    remove_column :companies, :bank_journal_id
    remove_column :companies, :invoice_sequence_id
  end

  def self.down
    add_column :companies, :invoice_sequence_id, :integer, :references=>:sequences
    add_column :companies, :sales_journal_id, :integer, :references=>:journals, :on_delete=>:cascade, :on_update=>:cascade
    add_column :companies, :purchases_journal_id,:integer,:references=>:journals,:on_delete=>:cascade, :on_update=>:cascade
    add_column :companies, :bank_journal_id, :integer, :references=>:journals, :on_delete=>:cascade, :on_update=>:cascade

    add_column :parameters, :element_id, :integer
    add_column :parameters, :element_type, :string

    
    for company in connection.select_all("SELECT * FROM #{quoted_table_name(:companies)}")
      for journal in [:sales, :purchases, :bank]
        parameter = select_one("SELECT record_value_id FROM #{quoted_table_name(:parameters)} WHERE name LIKE 'accountancy.default_journals.#{journal}'")
        execute "UPDATE #{quoted_table_name(:companies)} SET #{journal}_journal_id=#{parameter['record_value_id']}" if parameter
      end
      parameter = select_one("SELECT record_value_id FROM #{quoted_table_name(:parameters)} WHERE name LIKE 'management.invoicing.numeration'")
      execute "UPDATE #{quoted_table_name(:companies)} SET invoice_sequence_id=#{parameter['record_value_id']}" if parameter
    end

    execute "DELETE FROM #{quoted_table_name(:parameters)} WHERE name LIKE 'accountancy.default_journals.%'"
    execute "DELETE FROM #{quoted_table_name(:parameters)} WHERE name LIKE 'management.invoicing.numeration'"

    for k, v in CONVERSIONS
      execute "UPDATE #{quoted_table_name(:parameters)} SET nature='#{k}' WHERE nature='#{v}'"
    end
    execute "UPDATE #{quoted_table_name(:parameters)} SET element_id = record_value_id, element_type = record_value_type"

    change_column :parameters, :nature, :string, :limit=>1
    remove_column :parameters, :record_value_id
    remove_column :parameters, :record_value_type
  end
end
