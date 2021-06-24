require 'test_helper'

class IdeaDiagnosticTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  test 'assert valid' do
    idea_diagnostic = idea_diagnostics(:idea_diagnostic_001)
    assert idea_diagnostic.valid?
  end

end
