class HelpController < ApplicationController
  include ActionView::Helpers::TagHelper

  def search
    code  = content_tag(:h2,  'Aide')
    code += content_tag(:div, params[:id])
    file_name  = params[:id]

    # Check cache
    # Else check texts
    #   Replace <<x>> and <<x|Label>> with results of link_to_remote
    #   Textilize
    #   Save in cache
    # return HTML
    code += content_tag(:br, '')

    file_text  = "app/languages/fr/help/"+file_name+".txt"
    file_cache = "app/languages/fr/help/cache/"+file_name+".html"

     User.current_user = User.find_by_id(session[:user_id])
      @current_user = User.current_user
      @current_company = @current_user.company
       
    if File.exists?(file_cache)  # the file exists in the cache 
      code  += content_tag(:h4 , 'TestOKdans le cache') 
      file = File.open('app/languages/fr/help/cache/'+file_name+'.html' , 'r') # file in cache
      content = file.read
      content = textilize(content)
      code  += content_tag(:div, content) 
        
    else
      #elsif File.exists?(file_text)
      file = File.open('app/languages/fr/help/'+file_name+'.txt' , 'r') # text file 

     
      content = file.read
      ltr = link_to_remote('\4', :url => { :action => "search", :id => '\1' }, :update => :help)
      content  =  content.gsub(/<<(\w+)((\|)(\w+))>>/ , ltr )

      
      content = textilize(content)
      code  += content_tag(:div, content)
      file_new = File.new("app/languages/fr/help/cache/"+file_name+".html" , "a+")
      file_new = content
      FileUtils.cp(file_new , 'app/languages/fr/help/cache/'+file_name+'.html')
      #else ... ?
     
    
      
      code += content_tag(:h4 ,'TestOk hors cache')
    end
    
   
    file.close 


    code  = content_tag(:div, code, :id=>:help, :flex=>1)
    render :text=>code
  
  end


end
