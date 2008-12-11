# == Schema Information
# Schema version: 20080808080808
#
# Table name: menu_items
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  menu_id      :integer       not null
#  parent_id    :integer       not null
#  url          :string

class MenuItem < ActiveRecord::Base

  acts_as_tree :order => :position
  acts_as_list :scope => :parent_id

 

end

=begin

def options_for_menu_items(menu_items)
   @ret = []
   for item in menu_items
     #if item.parent_id == 0
       @ret << [item.name ,item.id , item.position, item.url]
       @ret += options_for_submenu_items(item)
     #end
   end
   @ret
 end

 def options_for_submenu_items(item)
   @ret = []
   if item.children.size > 0
     item.children.each do |subcat|
       @ret << [ subcat.name, subcat.id, subcat.position ,subcat.url]
       #if subcat.children.size > 0           #inutile si 2 niveaux?
        # ret += options_for_subcategories(subcat, level)
       #end
     end
   end
   @ret
 end
 
 def display_items()
   #si l'item doit toujours affiché (item.parent = nil)
     # afficher item
   #si souris pointe sur item
     #  afficher sous_items


   if item.parent = nil # the item is always displayed
   end

   else
     display_children(item)
   end
     

 end


=end


=begin
 def display_categories(menu_items)
   ret = "<ul>"
   for item in menu_items
     if item.parent_id.nil?
       ret << display_category(item)
     end
   end
   ret << "</ul>"
 end
 
 def find_all_subcategories(item)
   ret = "<ul>"
   item.children.each do |subcat|
     ret << display_category(subcat)
   end
   ret << "</ul>"
 end
 
 def display_category(item)
   ret = "<li>"
   if item.children.any?
     ret << link_to(item.name , item.url)
   else
     ret << link_to(:item.name , {:controller=>:item.parent_id.name, :action=>item.name})
   end
   #ret << find_all_subcategories(item) if item.children.any?
   ret << "</li>"
 end
 
 
=end
