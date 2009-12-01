# == Schema Information
#
# Table name: listings
#
#  comment      :text          
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  query        :text          
#  root_model   :string(255)   not null
#  story        :text          
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class Listing < ActiveRecord::Base
  belongs_to :company
  has_many :nodes, :class_name=>ListingNode.name
  attr_readonly :company_id

  #validates_format_of :query, :with=>/\s*SELECT\s+[^\;]*/i

  def root_model_name
    ::I18n.t("activerecord.models."+self.root_model.underscore)
  end

  def before_validation
    #self.query == self.generate if self.id
  end

  def after_create
    self.query = ""
  end

  def root
    self.nodes.find_by_parent_id(nil)||self.nodes.create!(:label=>self.root_model_name, :name=>self.root_model, :nature=>"root")
  end

  def generate
    root = self.root
    self.query = "SELECT #{self.selected_attr} FROM #{root.model.table_name} AS #{root.key}"
    self.query += root.complete_query(root.key)
    self.query += self.conditions
    #raise Exception.new "okkjj"+self.query.inspect
    self.save
  end

  def selected_attr
    attrs = []
    for node in self.columns
      name = I18n::t('activerecord.attributes.'+node.parent.name.singularize+'.'+node.name)
     # raise Exception.new name.inspect
      attrs << "#{node.parent.key}.#{node.name} AS \"#{name}\" "
    end
    attrs = attrs.join(", ")
  end
  
  def conditions
    if self.reflections.size > 0
      c = "WHERE  "
      cs = []
      for node in self.reflections
        if node.name == "company"
          cs << "COALESCE(#{node.key}.id, CURRENT_COMPANY) = CURRENT_COMPANY" 
        else
          cs << "COALESCE(#{node.key}.company_id, CURRENT_COMPANY) = CURRENT_COMPANY"
        end
      end
      c += cs.join(" AND ")
      return c
    end
  end

  def reflections
    self.nodes.find(:all, :conditions=>["nature IN (?)", ["belongs_to", "has_many", "root"]])
  end

  def columns
    self.nodes.find_all_by_nature("column")
  end


end
