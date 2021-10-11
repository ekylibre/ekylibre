class AddLegalPositionCodeToEntities < ActiveRecord::Migration[4.2]
  def change
    add_column :entities, :legal_position_code, :string
  end
end
