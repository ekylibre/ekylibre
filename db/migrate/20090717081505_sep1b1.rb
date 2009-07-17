class Sep1b1 < ActiveRecord::Migration
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
    
    for company in Company.all
      Entity.update_all({:siren=>company.siren}, {:id=>company.entity_id})
      sequence = Sequence.new(:name=>'Numéros de facture', :format=>'F[year][month|2][number|6]', :period=>'month', :company_id=>company.id)
      sequence.send(:create_without_callbacks)
      Company.update_all({:invoice_sequence_id=>sequence['id']}, {:id=>company.id})
    end

    remove_column :companies, :siren
    
  end

  def self.down
    add_column    :companies, :siren, :string, :limit=>9, :null=>false, :default=>"000000000"

    for company in Company.all
      Company.update_all({:siren=>company.entity.siren}, {:id=>company.entity_id}) if company.entity
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
