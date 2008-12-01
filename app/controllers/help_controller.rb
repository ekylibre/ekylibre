class HelpController < ApplicationController
  include ActionView::Helpers::TagHelper


  def search
    session[:help]=true
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

       
    if File.exists?(file_cache)  # the file exists in the cache 

      code  += content_tag(:h4 , 'TestOKdans le cache') 
      file = File.open('app/languages/fr/help/cache/'+file_name+'.html' , 'r')
      content = file.read
      code  += content_tag(:div, content) 
        
    elsif File.exists?(file_text) # the file doesn't exist in the cache, but exits as a text file

      file = File.open('app/languages/fr/help/'+file_name+'.txt' , 'r')
      content = file.read
      ltr = link_to_remote('\4', :url => { :action => "search", :id => '\1' }, :update => :help) 
      content  =  content.gsub(/<<(\w+)((\|)(\w+))>>/ , ltr )
      content = textilize(content)
      code  += content_tag(:div, content)
      file_new = File.new("app/languages/fr/help/cache/"+file_name+".html" , "a+") # create cache file
      file_new = File.open('app/languages/fr/help/cache/'+file_name+'.html' , 'wb')
      file_new.write(content )
      file_new.close
      code += content_tag(:h4 ,'TestOk hors cache')

    else # no help file for this section

      code  += content_tag(:h4 , 'TestOK No file') 
      file = File.open('app/languages/fr/help/cache/start-help.html' , 'r')
      content = file.read
      code  += content_tag(:div, content) 
  
    end
       
    file.close 
    code  = content_tag(:div, code, :id=>:help, :flex=>1)
    render :text=>code
 
  end

  def close
    session[:help]=false
  end

end
