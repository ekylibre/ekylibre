class SearchController < ApplicationController
   dyli :role_search, :attributes => [:name, :actions], :model => :role
  
  def test
    @user = User.new
  end
  
end

