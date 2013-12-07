ActiveRecord::ConnectionAdapters::TableDefinition.class_eval do

  def stamps(options = {})
    groups = [:time, :user, :lock]
    groups &= [options.delete(:only)].flatten if options[:only]
    groups -= [options.delete(:except)].flatten if options[:except]
    if groups.include?(:time)
      self.datetime(:created_at, null: false)
      self.datetime(:updated_at, null: false)
      self.index(:created_at)
      self.index(:updated_at)
    end
    if groups.include?(:user)
      self.references(:creator, index: true)
      self.references(:updater, index: true)
    end
    if groups.include?(:lock)
      self.integer(:lock_version, null: false, default: 0)
    end
  end

end
