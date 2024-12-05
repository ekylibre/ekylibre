class AddEmailTemplates < ActiveRecord::Migration[5.2]
  def change
    create_table :email_templates do |t|
      t.text :body, null: false
      t.boolean :by_default, null: false, default: false
      t.string :name, index: true, null: false
      t.string :nature
      t.string :language
      t.string :path
      t.string :locale
      t.string :handler
      t.boolean :partial, null: false, default: false
      t.string :format
      t.jsonb :metadata, default: {}
      t.stamps
    end
    add_column :sales, :last_email_at, :datetime
  end
end


