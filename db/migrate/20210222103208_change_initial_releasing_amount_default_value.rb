# frozen_string_literal: true

class ChangeInitialReleasingAmountDefaultValue < ActiveRecord::Migration[5.0]
  def up
    change_column_default(:loans, :initial_releasing_amount, true)
  end

  def down
    change_column_default(:loans, :initial_releasing_amount, false)
  end
end
