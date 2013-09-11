ActiveRecord::ConnectionAdapters::TableDefinition.class_eval do

  def stamps
    self.datetime(:created_at, null: false)
    self.datetime(:updated_at, null: false)
    self.references(:creator, index: true)
    self.references(:updater, index: true)
    self.integer(:lock_version, null: false, default: 0)
    self.index(:created_at)
    self.index(:updated_at)
  end

end
