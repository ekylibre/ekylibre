class SearchController < ApplicationController
#  dyli :account_partial, :attributes => [:name, :number], :model => :account, :partial => :test
    
  def index()
    @entry = Entry.new if request.get?
    raise Exception.new('params:'+params.inspect) if request.post? 
  end
  
end

