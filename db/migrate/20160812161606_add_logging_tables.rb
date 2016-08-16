class AddLoggingTables < ActiveRecord::Migration
  def change
    create_table :call_messages do |t|
      t.string      :status
      t.string      :headers
      t.text        :body

      t.string      :type

      t.string      :ip
      t.string      :url
      t.string      :format

      t.string      :source

      t.string      :method

      t.references  :request,   index: true
      t.references  :operation, index: true
    end

    create_table :calls do |t|

    end
  end
end
