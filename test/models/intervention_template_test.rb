require 'test_helper'

class InterventionTemplateTest < ActiveSupport::TestCase
  test "have a validate factory" do
    intervention_template = build(:intervention_template)
    assert true, intervention_template.valid?
  end
end
