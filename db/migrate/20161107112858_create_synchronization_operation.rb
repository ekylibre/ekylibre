class CreateSynchronizationOperation < ActiveRecord::Migration
  def change
    create_table :synchronization_operations do |t|
      t.string :operation_name, null: false, index: true
      t.string :state, null: false
      t.datetime :finished_at
      t.references :notification
      t.jsonb :request
      t.jsonb :response
      t.stamps
    end

    add_reference :calls, :source, polymorphic: true, index: true
  end
end
