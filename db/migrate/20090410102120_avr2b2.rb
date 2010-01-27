class Avr2b2 < ActiveRecord::Migration
  def self.up
    add_column :complement_choices, :position, :integer
    for complement in Complement.find(:all)
      complement.sort_choices
    end
  end

  def self.down
    remove_column :complement_choices, :position
  end
end
