class SearchController < ApplicationController
  
  dyli(:account, :fields => [:name], :instance => @current_company, :size => 5)
  
  def test
 #   dyli( :entity, :fields => [:name], :size => 5)
    #dyli(:journal, :fields => [:name, :nature], :size => 6)
    #journal_dyli_build
    # render :text => journal_dyli_build()
    #journal_dyli_list
	#if request.xhr?
	#puts 'v:'+params[:p].to_s 
		#entity_dyli_list params[:search] 
#puts params[:search].to_s    
	account_dyli_list params if request.xhr?
  end
  
end

#  module Controller
    
#     def self.included(base)
#       base.extend(ClassMethods)
#     end
    
    
#      module ClassMethods
      
#       include ERB::Util
#       include ActionView::Helpers::TagHelper
#       include ActionView::Helpers::UrlHelper

#      # class Base
      
#       # 
#       def dyli(name, options={:fields => [:name], :size => 5})
#         code = "" 
#         model = name.to_s.classify.constantize
        
#         fields="[\""+options[:fields].collect {|field| field.to_s+" LIKE ? "}.join("AND ")+"\""
        
#         code += "def "+name.to_s+"_dyli_list(params={:search=>''})\n"
#         code += "div_html_text=''\n"
#         code += "puts 'oui:'+params[:search].to_s\n"
#         code += "unless params[:search].empty?\n"
#         code += name.to_s.pluralize+"="+model.to_s+".find(:all, :conditions => "+fields
#         (options[:fields].size).times do
#           code += ", params[:search]+'%'"
#         end
#         code += "], :limit => "+options[:size].to_s+")\n"
        
#         code += name.to_s.pluralize+".each do |"+name.to_s+"| \n"
#         code += "div_html_text += content_tag(:div,"
#         code += options[:fields].collect {|column| name.to_s+"."+column.to_s}.join("+', '+")
#         code +=")\n"
#         code += "end\n"
#         code += "render :text =>div_html_text.to_s\n"
#         code += "else\n return 'iui'\n"
#         code += "end\n"
#         code += "end \n"
        
#         # puts(code)
#         if RAILS_ENV=="development"
#           f=File.open('dyli.rb','wb')
#           f.write(code)
#           f.close()
#         end
        
#         ActionController::Base.module_eval(code)
#       end

#     end
#   end

#   module View
#     #class Base
      
#       def dyli_field(name)
#          form_dyli = ''
#          form_dyli += content_tag :label, 'Entrez votre recherche:', {:name => 'search'}
#          form_dyli += tag :input, {:type =>'text', :name =>'search', :id =>'search'}
#          form_dyli += tag :input, {:type => 'hidden', :name => 'search_hidden'}
#          form_dyli += observe_field 'search', :frequency => 0.25,:update => 'tf_id_auto_complete', :with => 'search='+escape(value)
# #         form_dyli += tag(:div,:id =>'tf_id_auto_complete')
# #         ,:url => {:action => #{name.to_s}_dyli_list}
#         render :text => form_dyli
          
#       end
        
#   end
# #end
    
