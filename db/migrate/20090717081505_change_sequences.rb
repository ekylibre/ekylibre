class ChangeSequences < ActiveRecord::Migration
  def self.up
    remove_column :sequences, :increment
    remove_column :sequences, :next_number
    remove_column :sequences, :active

    add_column    :sequences, :period, :string, :null=>false, :default=>'number'
    add_column    :sequences, :last_year,   :integer
    add_column    :sequences, :last_month,  :integer
    add_column    :sequences, :last_cweek,  :integer
    add_column    :sequences, :last_number, :integer
    add_column    :sequences, :number_increment, :integer, :null=>false, :default=>1
    add_column    :sequences, :number_start, :integer, :null=>false, :default=>1

    add_column    :companies, :invoice_sequence_id, :integer
    add_column    :entities,  :siren, :string, :limit=>9
    
    companies = select_all("SELECT * FROM companies")
    if companies.size > 0
      execute "UPDATE entities SET siren=CASE "+companies.collect{|c| "WHEN company_id=#{c['id']} THEN '#{c['siren']}'"}.join(" ")+" ELSE 0 END"
      execute "INSERT INTO sequences(name, format, period, company_id, created_at, updated_at) SELECT 'Numéros de facture', 'F[year][month|2][number|6]', 'month', id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM companies"
      execute "UPDATE companies SET invoice_sequence_id=CASE "+select_all("SELECT * FROM sequences").collect{|s| "WHEN id=#{s['company_id']} THEN #{s['id']}"}.join(" ")+" ELSE 0 END"
    end

    remove_column :companies, :siren    
  end

  def self.down
    add_column    :companies, :siren, :string, :limit=>9, :null=>false, :default=>"000000000"

    for company in connection.select_all("SELECT * FROM companies")
      siren = connection.select_one("SELECT siren FROM entities WHERE id=#{company['entity_id']}")
      execute "UPDATE companies SET siren=#{siren} WHERE id=#{company['id']}" unless siren.blank?
    end

    execute "DELETE FROM sequences WHERE format='F[year][month|2][number|6]'"

    remove_column :entities,  :siren
    remove_column :companies, :invoice_sequence_id

    remove_column :sequences, :number_start
    remove_column :sequences, :number_increment
    remove_column :sequences, :last_number
    remove_column :sequences, :last_cweek
    remove_column :sequences, :last_month
    remove_column :sequences, :last_year
    remove_column :sequences, :period

    add_column    :sequences, :active, :boolean, :null=>false, :default=>false
    add_column    :sequences, :next_number, :integer, :null=>false, :default=>0
    add_column    :sequences, :increment, :integer, :null=>false, :default=>1
  end
end
