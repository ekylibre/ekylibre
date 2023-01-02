# frozen_string_literal: true

class InterventionModelItem < LexiconRecord
  include Lexiconable
  belongs_to :intervention_model, class_name: 'InterventionModel', foreign_key: :intervention_model_id

  delegate :procedure, to: :intervention_model
  delegate :type, to: :parameter, prefix: true, allow_nil: true

  def parameter
    return nil if procedure.nil? || procedure_item_reference.nil?

    procedure.find(procedure_item_reference)
  end

  def product_parameter_type
    ('intervention_template/' + parameter_type.to_s).camelize
  end
end
