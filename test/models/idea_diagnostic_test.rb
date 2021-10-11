require 'test_helper'

class IdeaDiagnosticTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures

  setup do
    IdeaDiagnostic.delete_all
    @diagnostic = create(:idea_diagnostic)
  end

  test_model_actions

  test 'valid diagnostic' do
    assert @diagnostic.valid?
  end
end
