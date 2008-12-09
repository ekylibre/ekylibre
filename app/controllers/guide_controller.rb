class GuideController < ApplicationController
 
  def welcome
    redirect_to :action=>:index
  end

  def index
  end

  def accountancy
  end

  def sales
    @menu = 1          # Menu.new
  end

  def purchases
  end

  def stocks
  end
	
end
