class EntityBalance < Ekylibre::Record::Base
  self.primary_key = 'id'

  belongs_to :entity, foreign_key: :id

  scope :unbalanced, -> { where('trade_balance != client_accounting_balance AND trade_balance != supplier_accounting_balance') }

  class << self
    def include?(record)
      find_by(id: record).present?
    end
  end
end
