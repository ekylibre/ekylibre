class Nov1t3 < ActiveRecord::Migration
  def self.up

    execute "UPDATE document_templates SET nature = code WHERE nature IS NULL"

  end

  def self.down
  end
end
