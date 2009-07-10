module HelpHelper
  

  def retrieve(file_name,options={})
    file_name||=''
    content = ''
    error = ''
    default = options[:default]
    help_root = "#{RAILS_ROOT}/config/locales/"+I18n.locale.to_s+"/help/"
    file_text  = help_root+file_name+".txt"
    file_cache = help_root+"cache/"+file_name+".html"
    
    if File.exists?(file_cache) and ENV["RAILS_ENV"]!="development"
      # the file exists in the cache 
      file = File.open(file_cache , 'r')
      content = file.read
    elsif File.exists?(file_text)  # the file doesn't exist in the cache, but exits as a text file
      file = File.open(file_text, 'r')
      content = file.read
      # {{buttons/update.png|Label}}
      url = url_for(:controller=>:images)
      content = content.gsub(/\{\{([^\}]+)((\|)([^}]+))\}\}/, '!'+url+'/\1(\4)!')
      content = content.gsub(/\{\{([^\}]+)\}\}/, '!'+url+'/\1!' )
      # <<controller-action|Label>>
      ltr = link_to_remote('\4', :url => {:controller=>:help, :action=>"search", :article=>'\1'}, :update => :help).gsub('%5C',"\\")
      content = content.gsub(/<<([\w\-]+)((\|)([^>]+))>>/ , ltr )
      # <<controller-action>>
      ltr = link_to_remote('\1', :url => {:controller=>:help, :action=>"search", :article=>'\1'}, :update => :help).gsub('%5C',"\\")
      content = content.gsub(/<<([\w\-]+)>>/ , ltr )
      content = content.squeeze(' ')
#      content = content.gsub(/(\ *)(\:|\?)/ , '~\2' )
      content = content.gsub(/\~/ , '&nbsp;' )
      content = textilize(content)
      file_new = File.new(file_cache, "a+") # create new cache file
      file_new = File.open(file_cache, 'wb')
      file_new.write(content)
      file_new.close
      file.close
    end
 
    content = retrieve(default) if content.blank? and not default.blank?
    return content
  end

  def wikize(name, options={})
    name||=''
    content = ''
    default = options[:default]
    file_text = "#{RAILS_ROOT}/config/locales/"+I18n.locale.to_s+"/help/"+name+".txt"
    
    if File.exists?(file_text)  # the file doesn't exist in the cache, but exits as a text file
      File.open(file_text, 'r') do |file|
        content = file.read
      end
      # {{buttons/update.png|Label}}
      url = url_for(:controller=>:images)
      content = content.gsub(/\{\{([^\}]+)((\|)([^}]+))\}\}/, '!'+url+'/\1(\4)!')
      content = content.gsub(/\{\{([^\}]+)\}\}/, '!'+url+'/\1!' )
      # <<controller-action|Label>>
      ltr = link_to_remote('\4', :url => {:controller=>:help, :action=>"search", :article=>'\1'}, :update => :help).gsub('%5C',"\\")
      content = content.gsub(/<<([\w\-]+)((\|)([^>]+))>>/ , ltr )
      # <<controller-action>>
      ltr = link_to_remote('\1', :url => {:controller=>:help, :action=>"search", :article=>'\1'}, :update => :help).gsub('%5C',"\\")
      content = content.gsub(/<<([\w\-]+)>>/ , ltr )
      content = content.squeeze(' ')
      #      content = content.gsub(/(\ *)(\:|\?)/ , '~\2' )
      content = content.gsub(/\~/ , '&nbsp;' )
      content = textilize(content)
    end
    content = wikize(default) if content.blank? and not default.blank?
    return content
  end


end
