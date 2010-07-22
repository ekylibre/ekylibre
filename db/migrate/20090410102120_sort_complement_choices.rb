class SortComplementChoices < ActiveRecord::Migration
  def self.up
    add_column :complement_choices, :position, :integer
    if defined? Complement
      for complement in Complement.find(:all)
        complement.sort_choices
      end
    end
  end

  def self.down
    remove_column :complement_choices, :position
  end
end
