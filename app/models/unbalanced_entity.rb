class UnbalancedEntity < Ekylibre::Record::Base
  self.primary_key = 'id'

  belongs_to :entity, foreign_key: :id

  class << self
    def include?(record)
      find_by(id: record).present?
    end
  end
end
