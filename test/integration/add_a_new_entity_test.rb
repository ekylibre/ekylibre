require 'test_helper'

class AddANewEntityTest < CapybaraIntegrationTest
  
  test "adding an entity" do
    visit('/session/new')
    fill_in('name', :with => 'gendo')
    fill_in('password', :with => 'secret')
    click_button(I18n.translate('labels.connect'))
    visit('/entities')
    visit('/subscriptions')
    visit('/accounts')
    visit('/sales')
    visit('/purchases')
  end

end
