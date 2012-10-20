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

class ProductionChainsController < AdminController
  manage_restfully 

  list(:order=>"name") do |t|
    t.column :name, :url=>true
    t.column :comment
    t.action :edit
    t.action :destroy
  end

  # Displays the main page with the list of production chains
  def index
    if params[:generate] == "sample"
      ActiveRecord::Base.transaction do
        building = Warehouse.where(:reservoir=>false).first
        name = "Sample production chain (手本)"
        pc = ProductionChain.find_by_name(name)
        pc.destroy if pc
        pc = ProductionChain.create!(:name=>name)
        ops = {}
        for op, long_name in {:a=>"Cooling", :b=>"Sorting", :c=>"Packaging Q1S1", :d=>"Packaging Q1S2", :e=>"Packaging Q2S1", :f=>"Packaging Q2S2", :g=>"Packaging Special Palet"}.sort{|a,b| a.to_s<=>b.to_s}
          name = long_name.split(/\s+/)[0]
          n = OperationNature.find_by_name(name)
          n = OperationNature.create!(:name=>name) if n.nil?
          ops[op] = pc.operations.create!(:name=>long_name, :building=>building, :nature=>(long_name.match(/\s/) ? "output" : "input"), :operation_nature=>n)
        end
        us = {}
        us[:kg] = Unit.find_by_name("kg")||Unit.create!(:name=>"kg", :label=>"Kilogram", :base=>"kg")
        us[:u]  = Unit.find_by_name("u") ||Unit.create!(:name=>"u", :label=>"Unit", :base=>"")
        ps = {}
        for p in [["TOMA", "Tomato (トマト)", :kg, 1],
                  ["TO11", "Tomato Q1S1 (トマト)", :kg, 1],
                  ["TO12", "Tomato Q1S2 (トマト)", :kg, 1],
                  ["TO21", "Tomato Q2S1 (トマト)", :kg, 1],
                  ["TO22", "Tomato Q2S2 (トマト)", :kg, 1],
                  ["BOX1", "Box S1 (匣)", :u, 0.040],
                  ["BOX2", "Box S2 (匣)", :u, 0.070],
                  ["TB11", "Tomato Box Q1S1 (トマトの匣)", :u, 1.04],
                  ["TB12", "Tomato Box Q1S2 (トマトの匣)", :u, 2.07],
                  ["TB21", "Tomato Box Q2S1 (トマトの匣)", :u, 1.04],
                  ["TB22", "Tomato Box Q2S2 (トマトの匣)", :u, 2.07],
                  ["STPA", "Special Tomato Palet (トマトの匣)", :u, 925] # 912.8 of tomato + palet (12kg) + film
                 ]
          k = p[0] # .lower.to_sym
          ps[k] = Product.find_by_code(p[0])
          # ps[k].destroy; ps[k] = nil
          ps[k] = Product.create!(:name=>p[1], :code=>p[0], :unit=>us[p[2]], :weight=>p[3], :for_sales=>false, :category=>ProductCategory.first, :nature=>"product", :stockable=>true) unless ps[k]
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
                    ["TB11",  :c, 1.0,  :g, 200, false, true],
                    ["TB12",  :d, 1.0,  :g, 120, false, true],
                    ["TB21",  :e, 1.0,  :g, 200, false, true],
                    ["TB22",  :f, 1.0,  :g, 120, false, true],
                    ["STPA",  :g, 1.0, nil,   0, false, true]
                  ]
          pc.conveyors.create!(:product=>ps[co[0]], :source=>ops[co[1]], :source_quantity=>co[2], :target=>ops[co[3]], :target_quantity=>co[4], :check_state=>co[5], :unique_tracking=>co[6]||false)
        end
        redirect_to :action=>:show, :id=>pc.id
      end
    end
  end



  list(:work_centers, :model=>:production_chain_work_centers, :order=>"name") do |t|
    t.column :name, :url=>true
    t.column :name, :through=>:operation_nature
    t.column :nature
    t.column :name, :through=>:building, :url=>true
    t.column :comment
    t.action :edit
    t.action :destroy
  end

  list(:conveyors, :model=>:production_chain_conveyors, :order=>"id") do |t|
    t.column :name, :through=>:product, :url=>true
    t.column :flow
    t.column :name, :through=>:unit
    t.column :name, :through=>:source, :url=>true
    t.column :name, :through=>:target, :url=>true
    t.action :edit
    t.action :destroy
  end

  # Displays details of one production chain selected with +params[:id]+
  def show
    return unless @production_chain = find_and_check(:production_chain)
    t3e @production_chain.attributes
  end

end
