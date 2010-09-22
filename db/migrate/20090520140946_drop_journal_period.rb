class DropJournalPeriod < ActiveRecord::Migration
  def self.up
    add_column :journal_records, :closed, :boolean, :default => false
    add_column :journal_records, :financialyear_id, :integer, :references => :financialyears, :on_delete=>:restrict, :on_update=>:cascade 

    if defined? JournalPeriod
      JournalPeriod.find(:all).each do |period| 
        period.records.each do |record| 
          record.closed =  period.closed
          record.financialyear_id = period.financialyear_id
          record.journal_id = period.journal_id
          record.save(false)
        end
      end
    end

    remove_index :journal_records, :column=>[:period_id]
    remove_index :journal_records, :column=>[:period_id, :number]
    remove_column :journal_records, :period_id
    drop_table :journal_periods
    remove_column :financialyears, :written_on
  end
  

  def self.down
    add_column :financialyears, :written_on, :date
    
    create_table :journal_periods do |t|
      t.column :journal_id,       :integer, :null=>false, :references=>:journals, :on_delete=>:restrict, :on_update=>:cascade
      t.column :financialyear_id, :integer, :null=>false, :references=>:financialyears, :on_delete=>:restrict, :on_update=>:cascade
      t.column :started_on,       :date,    :null=>false
      t.column :stopped_on,       :date,    :null=>false
      t.column :closed,           :boolean, :default=>false
      t.column :debit,            :decimal, :null=>false, :default=>0, :precision=>16, :scale=>2
      t.column :credit,           :decimal, :null=>false, :default=>0, :precision=>16, :scale=>2
      t.column :balance,          :decimal, :null=>false, :default=>0, :precision=>16, :scale=>2
      t.column :company_id,       :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :journal_periods, :company_id
    add_index :journal_periods, :journal_id
    add_index :journal_periods, :financialyear_id
    add_index :journal_periods, :started_on
    add_index :journal_periods, :stopped_on
    add_index :journal_periods, [:started_on, :stopped_on, :journal_id, :financialyear_id, :company_id], :unique=>true, :name=>"#{quoted_table_name(:journal_periods)}_unique"
    
    
    add_column :journal_records, :period_id, :integer, :references => :journal_periods, :on_delete=>:restrict, :on_update=>:cascade 

    execute "INSERT INTO #{quoted_table_name(:journal_periods)} (journal_id, financialyear_id, started_on, stopped_on, closed, company_id, created_at, updated_at) select distinct journal_id, coalesce(financialyear_id, 0), CAST("+connection.concatenate("extract(year from created_on)", "'-'", "extract(month from created_on)", "'-01'")+" AS date),  cast("+connection.concatenate("extract(year from created_on)", "'-'", "extract(month from created_on)", "'-28'")+" AS date), closed, company_id, current_timestamp, current_timestamp from #{quoted_table_name(:journal_records)}"

    if defined? JournalPeriod
      JournalPeriod.find(:all).each do |period| 
        period.stopped_on=period.stopped_on.end_of_month
        period.save(false)
      end
    end


    remove_column :journal_records, :financialyear_id
    remove_column :journal_records, :closed 
  end
end
