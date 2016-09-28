class CreateEdnotifLogger < ActiveRecord::Migration
  def change
    create_table :ednotif_loggers do |t|
      t.string :operation_name, null: false, index: true
      t.string :state
      t.stamps
    end

    add_reference :calls, :source, polymorphic: true, index: true
  end
end
