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
    code += content_tag(:a ,  '/app/languages/fr/help/exemple.txt')

    file_text  = "app/languages/fr/help/"+file_name+".txt"
    file_cache = "app/languages/fr/help/cache/"+file_name+".html"
       
    if File.exists?(file_cache)  # the file exists in the cache
      then 
      code  += content_tag(:h1 , 'TestOKdans le cache') 

      i = 1
      file = File.open('app/languages/fr/help/cache/'+file_name+'.html' , 'r')
     # file = File.open('app/languages/fr/help/'+file_name+'.txt', 'r') # text file, not cache file
      file.each_line { |lign|
          line = "#{i} - #{lign}"        
          code  += content_tag(:h2, line)
          i += 1
      }

      else
      code += content_tag(:h1 ,'TestNOk')
    end
   
    #file.close 


    code  = content_tag(:div, code, :id=>:help, :flex=>1)
    render :text=>code
  
  end


end
