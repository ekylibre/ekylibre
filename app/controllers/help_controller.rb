class HelpController < ApplicationController
  include ActionView::Helpers::TagHelper


  def search
    @id = params[:id]
    if session[:help_history] 
      @previous = session[:help_history][1] if session[:help_history].size>1
    end
    session[:help]=true
    render :partial=>'search'
  end

  def close    
    session[:help]=false
    session[:help_history] = []
    render :text=>''
  end


end
