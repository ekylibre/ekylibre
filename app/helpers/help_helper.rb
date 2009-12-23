# ##### BEGIN LICENSE BLOCK #####
# Ekylibre - Simple ERP
# Copyright (C) 2009 Brice Texier, Thibaud Mérigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# ##### END LICENSE BLOCK #####

module HelpHelper
  

  def retrievezzz(file_name,options={})
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




end
