class UnbalancedEntity < Ekylibre::Record::Base
  self.primary_key = 'id'

  class << self
    def include?(record)
      find(record).exists?
    end
  end
end
