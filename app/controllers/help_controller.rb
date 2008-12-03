class HelpController < ApplicationController
  include ActionView::Helpers::TagHelper
  
  
  def search
    @id = params[:id]    #.gsub('-',"//")
    if request.get?
      session[:help_history] = [] if session[:help_history].nil?
      if session[:help_history][0] != @id
        10.times{|i| session[:help_history][i+1] = session[:help_history][i]}
        session[:help_history][0] = @id
      end
    end
    
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
