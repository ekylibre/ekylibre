class CreateSensors < ActiveRecord::Migration
  def change
    create_table :sensors do |t|
      t.string :vendor_euid,  null: false
      t.string :model_euid, null: false
      t.string :name, null: false
      t.string :retrieval_mode, null: false
      t.json :access_parameters
      t.references :product, index: true
      t.boolean :embedded, default: false, null: false
      t.references :host, index: true
      t.boolean :active, default: true, null: false
      t.stamps
      t.index :vendor_euid
      t.index :model_euid
      t.index :name
    end

    add_reference :analyses, :host, index: true
    add_reference :analyses, :sensor, index: true
    add_column :analyses, :sampling_temporal_mode, :string, default: 'instant', null: false
    add_column :analyses, :stopped_at, :datetime
    add_column :analyses, :state, :string, default: 'ok', null: false
    add_column :analyses, :error_explanation, :string, null: true
  end
end
