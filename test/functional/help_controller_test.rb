require 'test_helper'

class HelpControllerTest < ActionController::TestCase
  test_restfully_all_actions  
  
  # include ApplicationHelper
  # include ActionView::Helpers::UrlHelper

  context 'Help controller' do
    setup do
      @current_company = companies(:companies_001)
    end


    for file in Dir.glob(Rails.root.join("config", "locales", "*", "help", "*.txt"))
      File.open(file, "rb") do |f|
        @source = f.read
        should "'wikize' #{file}" do
          assert_nothing_raised() do
            render :inline=>"<%=wikize(@source)-%>"
          end
        end
      end
    end

  end

  
end
