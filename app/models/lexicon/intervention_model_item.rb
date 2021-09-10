# frozen_string_literal: true

class InterventionModelItem < LexiconRecord
  include Lexiconable
  belongs_to :intervention_model, class_name: 'InterventionModel', foreign_key: :intervention_model_id
end
