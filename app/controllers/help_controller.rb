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
    code += content_tag(:b , 'app/languages/fr/help/'+file_name+'.txt' )
    code += content_tag(:br, '')

    file_text  = "app/languages/fr/help/"+file_name+".txt"
    file_cache = "app/languages/fr/help/cache/"+file_name+".html"
       
    if File.exists?(file_cache)  # the file exists in the cache 
      code  += content_tag(:h1 , 'TestOKdans le cache') 
      file = File.open('app/languages/fr/help/cache/'+file_name+'.html' , 'r') # file in cache
      code  += content_tag(:h4, file.read)
      #code  +=content_tag(:h4, textilize(file_cache))
        

    else
      file = File.open('app/languages/fr/help/'+file_name+'.txt' , 'r') # text file 

     
      content = file.read
      ltr = link_to_remote('\4', :url => { :action => "search", :id => '\1' }, :update => :help)
      content  =  content.gsub(/<<(\w+)((\|)(\w+))>>/ , ltr )

      
      content = textilize(content)
      code  += content_tag(:div, content)
      #FileUtils.cp ( content, 'app/languages/fr/help/cache/')
      
      code += content_tag(:h1 ,'TestOk hors cache')
    end
    
   
    #file.close 


    code  = content_tag(:div, code, :id=>:help, :flex=>1)
    render :text=>code
  
  end


end
