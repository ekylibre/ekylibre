class AddEmbankmentNumber < ActiveRecord::Migration
  def self.up

    add_column :embankments, :number, :string
    
    execute "UPDATE #{quoted_table_name(:embankments)} SET number = id WHERE number IS NULL"

    add_column :subscriptions, :number, :string

    execute "UPDATE #{quoted_table_name(:subscriptions)} SET number = id WHERE number IS NULL"

  end
  
  def self.down
    remove_column :subscriptions, :number
    remove_column :embankments, :number
  end
end
