require 'test_helper'

class AddANewEntityTest < CapybaraIntegrationTest


  test "adding an entity" do
    visit('/authentication/sign_in')
    fill_in('user_email', :with => 'gendo@nerv.jp')
    fill_in('user_password', :with => '12345678')
    click_button('Connexion')
    #visit('/backend/entities')
    #visit('/backend/subscriptions')
    #visit('/backend/accounts')
    #visit('/backend/sales')
    #visit('/backend/purchases')
  end

end
