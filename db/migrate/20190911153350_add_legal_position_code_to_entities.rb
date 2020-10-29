class AddLegalPositionCodeToEntities < ActiveRecord::Migration
  def change
    add_column :entities, :legal_position_code, :string
  end
end
