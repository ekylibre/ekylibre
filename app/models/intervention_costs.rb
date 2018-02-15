class InterventionCosts < Ekylibre::Record::Base
  has_one :intervention, inverse_of: :costs
end
