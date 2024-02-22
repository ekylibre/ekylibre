class AddUuidOnAp < ActiveRecord::Migration[5.2]
  def change
    add_column :activity_productions, :uuid, :uuid
  end
end


