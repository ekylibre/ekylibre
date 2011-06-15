# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
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

class ProductionChainsController < ApplicationController
  manage_restfully 

  list(:conditions=>{:company_id=>['@current_company.id']}, :order=>"name") do |t|
    t.column :name, :url=>{:action=>:production_chain}
    t.column :comment
    t.action :edit
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  # Displays details of one production chain selected with +params[:id]+
  def show
    return unless @production_chain = find_and_check(:production_chain)
    t3e @production_chain.attributes
  end

  # Displays the main page with the list of production chains
  def index
    if params[:generate] == "sample"
      ActiveRecord::Base.transaction do
        building = @current_company.warehouses.find(:all, :conditions=>{:reservoir=>false}).first
        name = "Sample production chain (手本)"
        pc = @current_company.production_chains.find_by_name(name)
        pc.destroy if pc
        pc = @current_company.production_chains.create!(:name=>name)
        ops = {}
        for op, long_name in {:a=>"Cooling", :b=>"Sorting", :c=>"Packaging Q1S1", :d=>"Packaging Q1S2", :e=>"Packaging Q2S1", :f=>"Packaging Q2S2", :g=>"Packaging Special Palet"}.sort{|a,b| a.to_s<=>b.to_s}
          name = long_name.split(/\s+/)[0]
          n = @current_company.operation_natures.find_by_name(name)
          n = @current_company.operation_natures.create!(:name=>name) if n.nil?
          ops[op] = pc.operations.create!(:name=>long_name, :building=>building, :nature=>(long_name.match(/\s/) ? "output" : "input"), :operation_nature=>n)
        end
        us = {}
        us[:kg] = @current_company.units.find_by_name("kg")||@current_company.units.create!(:name=>"kg", :label=>"Kilogram", :base=>"kg")
        us[:u] = @current_company.units.find_by_name("u")||@current_company.units.create!(:name=>"u", :label=>"Unit", :base=>"")
        ps = {}
        for p in [["TOMA", "Tomato (トマト)", :kg],
                  ["TO11", "Tomato Q1S1 (トマト)", :kg],
                  ["TO12", "Tomato Q1S2 (トマト)", :kg],
                  ["TO21", "Tomato Q2S1 (トマト)", :kg],
                  ["TO22", "Tomato Q2S2 (トマト)", :kg],
                  ["BOX1", "Box S1 (匣)", :u],
                  ["BOX2", "Box S2 (匣)", :u],
                  ["TB11", "Tomato Box Q1S1 (トマトの匣)", :u],
                  ["TB12", "Tomato Box Q1S2 (トマトの匣)", :u],
                  ["TB21", "Tomato Box Q2S1 (トマトの匣)", :u],
                  ["TB22", "Tomato Box Q2S2 (トマトの匣)", :u],
                  ["STPA", "Special Tomato Palet (トマトの匣)", :u]
                 ]
          k = p[0] # .lower.to_sym
          ps[k] = @current_company.products.find_by_code(p[0])
          # ps[k].destroy; ps[k] = nil
          ps[k] = @current_company.products.create!(:name=>p[1], :code=>p[0], :unit=>us[p[2]], :for_sales=>false, :category=>@current_company.product_categories.first, :nature=>"product", :stockable=>true) unless ps[k]
        end

        for co in [ ["TOMA", nil, 0.0,  :a,   1, true],
                    ["TOMA",  :a, 1.0,  :b,   1, true],
                    ["TO11",  :b, 0.2,  :c, 0.3, false],
                    ["TO12",  :b, 0.4,  :d, 0.5, false],
                    ["TO21",  :b, 0.3,  :e, 0.3, false],
                    ["TO22",  :b, 0.1,  :f, 0.5, false],
                    ["BOX1", nil, 0.0,  :c,   1, false],
                    ["BOX2", nil, 0.0,  :d,   1, false],
                    ["BOX1", nil, 0.0,  :e,   1, false],
                    ["BOX2", nil, 0.0,  :f,   1, false],
                    ["TB11",  :c, 1.0,  :g, 500, false, true],
                    ["TB12",  :d, 1.0,  :g, 300, false, true],
                    ["TB21",  :e, 1.0,  :g, 500, false, true],
                    ["TB22",  :f, 1.0,  :g, 300, false, true],
                    ["STPA",  :g, 1.0, nil,   0, false, true]
                  ]
          pc.conveyors.create!(:product=>ps[co[0]], :source=>ops[co[1]], :source_quantity=>co[2], :target=>ops[co[3]], :target_quantity=>co[4], :check_state=>co[5], :unique_tracking=>co[6]||false)
        end
        redirect_to :action=>:production_chain, :id=>pc.id
      end
    end
  end

end
