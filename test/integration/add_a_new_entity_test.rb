require 'test_helper'

class AddANewEntityTest < CapybaraIntegrationTest
  
  test "adding an entity" do
    visit('/myc')
    click_button(I18n.translate('labels.connect'))
  end
end
