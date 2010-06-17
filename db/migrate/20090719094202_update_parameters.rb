class UpdateParameters < ActiveRecord::Migration
  CONVERSIONS = {'s'=>'string', 'd'=>'decimal', 'b'=>'boolean', 'i'=>'integer', 'f'=>'record'}

  def self.up
    add_column :parameters, :record_value_id, :integer
    add_column :parameters, :record_value_type, :string
    change_column :parameters, :nature, :string, :limit=>8
    execute "UPDATE parameters SET record_value_id=element_id, record_value_type=element_type"

    for k, v in CONVERSIONS
      execute "UPDATE parameters SET nature='#{v}' WHERE nature='#{k}'"
    end
    
    for journal in ['sales', 'purchases', 'bank']
      execute "INSERT INTO parameters (name, nature, record_value_type, record_value_id, company_id, created_at, updated_at) SELECT 'accountancy.default_journals.#{journal}', 'record', 'Journal', #{journal}_journal_id, id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM companies"
    end
    execute "INSERT INTO parameters (name, nature, record_value_type, record_value_id, company_id, created_at, updated_at) SELECT 'management.invoicing.numeration', 'record', 'Sequence', invoice_sequence_id, id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM companies"

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

    for company in Company.all
      ['sales', 'purchases', 'bank'].each do |journal|
        parameter = company.parameter("accountancy.default_journals.#{journal}")
        company.send("#{journal}_journal_id=", parameter.value.id) if parameter and parameter.value
      end
      parameter = company.parameter("management.invoicing.numeration")
      company.invoice_sequence_id = parameter.value.id if parameter and parameter.value
      company.send(:update_without_callbacks)
    end
    Parameter.delete_all(["name LIKE ?", 'accountancy.default_journals.%'])
    Parameter.delete_all(["name = ?", 'management.invoicing.numeration'])

    for k, v in CONVERSIONS
      Parameter.update_all("nature='#{k}'","nature='#{v}'")
    end

    Parameter.update_all("element_id = record_value_id, element_type = record_value_type")
    change_column :parameters, :nature, :string, :limit=>1
    remove_column :parameters, :record_value_id
    remove_column :parameters, :record_value_type
  end
end
