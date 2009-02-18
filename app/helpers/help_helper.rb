module HelpHelper
  

  def retrieve(file_name,options={})
    content = ''
    error = ''
    default = options[:default]
    help_root = "#{RAILS_ROOT}/config/locales/"+I18n.locale.to_s+"/help/"
    file_text  = help_root+file_name+".txt"
    file_cache = help_root+"cache/"+file_name+".html"
    
    if File.exists?(file_cache) and ENV["RAILS_ENV"]!="development"
   # the file exists in the cache 
      file = File.open(file_cache , 'r')
      content =  file.read
    elsif File.exists?(file_text)  # the file doesn't exist in the cache, but exits as a text file
      file = File.open(file_text, 'r')
      content = file.read
      ltr = link_to_remote('\4', :url => { :controller=>:help , :action => "search", :id => '\1' }, :update => :help).gsub('%5C',"\\")
      content  =  content.gsub(/<<([\w\-]+)((\|)([^>]+))>>/ , ltr )
      ltr = link_to_remote('\1', :url => {:controller=>:help ,  :action => "search", :id => '\1' }, :update => :help).gsub('%5C',"\\")
      content  =  content.gsub(/<<([\w\-]+)>>/ , ltr )
      content = textilize(content)
      file_new = File.new(file_cache, "a+") # create new cache file
      file_new = File.open(file_cache, 'wb')
      file_new.write(content)
      file_new.close
      file.close
    end
 
    content = retrieve(default) if content.blank? and not default.blank?
#    if content.blank?
#      error = content_tag(:div, tc(:error_no_file, :value=>file_name), :class=>'help-error')
#      content = retrieve(default) unless default.blank?
#    end
    
#    content += content_tag(:div, '&nbsp;', :class=>'text-end')

#    return error+content_tag(:div, content, :class=>:data)
    return content.to_s
  end


end
