class CreateWiceGridSerializedQueries < ::ActiveRecord::Migration[4.2] #:nodoc:
  def change #:nodoc:
    create_table :wice_grid_serialized_queries do |t|
      t.column :name,      :string
      t.column :grid_name, :string
      t.column :query,     :text

      t.timestamps null: true
    end
    add_index :wice_grid_serialized_queries, :grid_name
    add_index :wice_grid_serialized_queries, %i[grid_name id]
  end
end
