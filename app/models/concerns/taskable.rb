module Taskable
  extend ActiveSupport::Concern

  included do
    belongs_to :operation
  end

  def intervention
    return (self.operation ? self.operation.intervention : nil)
  end

  def intervention_name
    return (self.operation ? self.operation.intervention_name : nil)
  end

end
