class AddLoggingTables < ActiveRecord::Migration
  def change
    create_table :call_messages do |t|
      t.string      :status
      t.string      :headers
      t.text        :body

      t.string      :type
      t.string      :nature, null: false

      t.string      :ip_address
      t.string      :url
      t.string      :format
      t.string      :ssl

      t.string      :verb

      t.references  :request, index: true
      t.references  :call, index: true
      t.stamps
    end

    create_table :calls do |t|
      t.string      :state # Needed for Async calls.
      t.string      :integration_name
      t.string      :name
      t.jsonb       :arguments
      t.stamps
    end
  end
end
