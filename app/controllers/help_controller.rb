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

    file = "app/languages/fr/help/+file_name.to_s+.txt"
       
    if File.exists?(file)
      code  += content_tag(:h1 , 'TestOK')   
    else
       code += content_tag(:h1 ,'TestNOk')
    
     # code += content_tag (:h1 , 'fichier existant')
  


  # fichier = File.open ("/app/languages/fr/help/exemple.txt", "r")
  #  i = 1
   # fichier.each_line { |ligne|
    #  lign = "#{i} - #{ligne}"
     # code += content_tag(:b , lign )
      #i += 1 

   # }
   # fichier.close

    code  = content_tag(:div, code, :id=>:help, :flex=>1)
    render :text=>code
  
    end


end
