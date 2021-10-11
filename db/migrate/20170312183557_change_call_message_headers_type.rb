class ChangeCallMessageHeadersType < ActiveRecord::Migration[4.2]
  def up
    change_column :call_messages, :headers, :text
  end

  def down
    change_column :call_messages, :headers, :string
  end
end
