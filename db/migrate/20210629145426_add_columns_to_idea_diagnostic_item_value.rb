class AddColumnsToIdeaDiagnosticItemValue < ActiveRecord::Migration[5.0]
  def change
    add_column :idea_diagnostic_item_values, :boolean_value, :boolean
    add_column :idea_diagnostic_item_values, :float_value, :float
    add_column :idea_diagnostic_item_values, :integer_value, :integer
    add_column :idea_diagnostic_item_values, :string_value, :string
    add_column :idea_diagnostic_item_values, :nature, :string, default: 'string'
    add_column :idea_diagnostic_items, :group, :string
    add_column :idea_diagnostic_items, :idea_id, :string
    add_column :idea_diagnostic_item_values, :name, :string
    add_column :idea_diagnostic_items, :value, :integer
    add_column :idea_diagnostic_items, :treshold, :integer
  end
end
