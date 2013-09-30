# -*- coding: utf-8 -*-
class Backend::ProductionsController < BackendController
  manage_restfully(:t3e => {:name => :name})

  unroll

  # params:
  #   :q Text search
  #   :s State search
  #   :campaign_id
  #   :product_nature_id
  def self.productions_conditions
    code = ""
    code = search_conditions(:productions => [:state], :activities => [:name], :product_natures => [:name]) + " ||= []\n"
    code << "unless params[:s].blank?\n"
    code << "  unless params[:s] == 'all'\n"
    # code << "    c[0] << \" AND state IN ('draft', 'validated', 'aborted', 'started')\"\n"
    # code << "  else\n"
    code << "    c[0] << \" AND state = ?\"\n"
    code << "    c << params[:s]\n"
    code << "  end\n"
    code << "end\n "
    code << "  if params[:campaign_id].to_i > 0\n"
    code << "    c[0] << \" AND \#{Campaign.table_name}.id = ?\"\n"
    code << "    c << params[:campaign_id].to_i\n"
    code << "  end\n"
    code << "  if params[:product_nature_id].to_i > 0\n"
    code << "    c[0] << \" AND \#{ProductNature.table_name}.id = ?\"\n"
    code << "    c << params[:product_nature_id].to_i\n"
    code << "  end\n"
    code << "c\n "
    code
  end



  list(:conditions => productions_conditions, :joins => [:activity, :product_nature, :campaign]) do |t|
    t.column :name, url: true
    t.column :name,through: :activity, url: true
    # t.column :name,through: :campaign, url: true
    # t.column :name,through: :product_nature, url: true
    t.column :state_label
    t.action :edit, :if => :draft?
    # t.action :print, :if => :validated?
    t.action :destroy, :if => :aborted?
  end

  # List supports for one production
  list(:supports, :model => :production_supports, :conditions => {production_id: 'params[:id]'.c}, :order => "created_at DESC") do |t|
    t.column :name, through: :storage, url: true
    t.column :shape_area, through: :storage
    t.column :created_at
  end

  # List procedures for one production
  list(:interventions, :conditions => {production_id: 'params[:id]'.c}, :order => "created_at DESC") do |t|
    # t.column :name
    t.column :procedure, url: true
    #t.column :name, through: :storage, url: true
    t.column :state
    t.column :name, through: :incident, url: true
    t.column :started_at
    t.column :stopped_at
    # t.column :provisional
  end

end
