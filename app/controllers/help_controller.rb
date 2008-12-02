class HelpController < ApplicationController
  include ActionView::Helpers::TagHelper


  def search
 
    code  = content_tag(:h2,  'Aide')
    file_name  = params[:id]

    code += content_tag(:br, '')

    code += content_tag(:div , retrieve(file_name,'start-help'))
    #code += content(:div , content_tag(:div , retrieve(file_name,'start-help')))
    #code += content_tag(:div , retrieve('start-help'))
       
    code  = content_tag(:div, code, :id=>:help, :flex=>1) 
    session[:help]=true
    render :text=>code
 
  end

  def close    
    session[:help]=false
  end

  hide_action :retrieve
  def retrieve(file_name,default=nil)
    content = ''
    file_text  = "app/languages/fr/help/"+file_name+".txt"
    file_cache = "app/languages/fr/help/cache/"+file_name+".html"
    
    
    if File.exists?(file_cache)    # the file exists in the cache 
      
      file = File.open('app/languages/fr/help/cache/'+file_name+'.html' , 'r')
      content =  file.read
                
      
    elsif File.exists?(file_text)  # the file doesn't exist in the cache, but exits as a text file
      
      file = File.open('app/languages/fr/help/'+file_name+'.txt' , 'r')
      content = file.read
      ltr = link_to_remote('\4', :url => { :action => "search", :id => '\1' }, :replace => :help) 
      content  =  content.gsub(/<<([\w\-]+)((\|)(.+))>>/ , ltr )
      ltr = link_to_remote('\1', :url => { :action => "search", :id => '\1' }, :update => :help) 
      content  =  content.gsub(/<<([\w\-]+)>>/ , ltr )
      content = textilize(content)
      file_new = File.new("app/languages/fr/help/cache/"+file_name+".html" , "a+") # create new cache file
      file_new = File.open('app/languages/fr/help/cache/'+file_name+'.html' , 'wb')
      file_new.write(content )
      file_new.close
      file.close
      
    elsif !default.blank? 
      content =  retrieve(default)# no help file for this section
      
    else
      content = lc :error_no_file
    end
    content
    
  end

end
