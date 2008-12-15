class GuideController < ApplicationController
 
  def index
  end

  def welcome
    redirect_to :action=>:index
  end

  def accountancy
  end

  def management
  end

  def about_us
  end

end
