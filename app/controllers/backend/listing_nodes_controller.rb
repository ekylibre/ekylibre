# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Backend::ListingNodesController < Backend::BaseController

  def new
    return unless @listing_node = find_and_check(id: params[:parent_id])
    if params[:nature]
      desc = params[:nature].split("-")
      # raise StandardError.new desc.inspect
      if desc[0] == "special"
        if desc[1] == "all_columns"
          model = @listing_node.model
          for column in model.content_columns.sort{|a,b| model.human_attribute_name(a.name.to_s)<=> model.human_attribute_name(b.name.to_s)}
            ln = @listing_node.children.new(:nature => "column", :attribute_name => column.name, :label => @listing_node.model.human_attribute_name(column.name))
            ln.save!
          end
        end
      else
        ln = @listing_node.children.new(:nature => desc[0], :attribute_name => desc[1], :label => @listing_node.model.human_attribute_name(desc[1]))
        ln.save!
      end
    end
    if request.xhr?
      render(:partial => "backend/listings/reflection", :object => @listing_node)
    else
      redirect_to backend_listing_url(@listing_node.listing)
    end
  end

  def create
    return unless @listing_node = find_and_check(id: params[:parent_id])
    render :text => "[UnfoundListingNode]" unless @listing_node
    desc = params[:nature].split("-")
    # raise StandardError.new desc.inspect
    if desc[0] == "special"
      if desc[1] == "all_columns"
        model = @listing_node.model
        for column in model.content_columns.sort{|a,b| model.human_attribute_name(a.name.to_s) <=>  model.human_attribute_name(b.name.to_s)}
          ln = @listing_node.children.new(:nature => "column", :attribute_name => column.name, :label => @listing_node.model.human_attribute_name(column.name))
          ln.save!
        end
      end
    else
      ln = @listing_node.children.new(nature: desc[0], attribute_name: desc[1], label: @listing_node.model.human_attribute_name(desc[1]))
      ln.save!
    end

    render(:partial => "backend/listings/reflection", :object => @listing_node)
  end

  def edit
    return unless @listing_node = find_and_check
    if request.xhr?
      if params[:type] == "hide" or params[:type] == "show"
        @listing_node.exportable = !@listing_node.exportable
        render :text => ""
      elsif params[:type] == "column_label"
        @listing_node.label = params[:label]
        render(:partial => "backend/listing_nodes/column_label", :object => @listing_node)
      elsif params[:type] == "comparison"
        @listing_node.condition_operator = params[:comparator]
        @listing_node.condition_value = params[:comparison_value]
        render(:partial => "backend/listing_nodes/comparison", :object => @listing_node)
      elsif params[:type] == "position"
        @listing_node.position = params[:position]
        render(:partial => "backend/listing_nodes/position", :object => @listing_node)
      else
        render(:text => "[ERROR] Unknown update type")
      end
      @listing_node.save
    else
      redirect_to backend_listings_url
    end
  end

  def update
    return unless @listing_node = find_and_check
    if request.xhr?
      if params[:type] == "exportable" # "hide" or params[:type] == "show"
        @listing_node.exportable = !@listing_node.exportable
        render :text => ""
      elsif params[:type] == "column_label"
        @listing_node.label = params[:label]
        render(:partial => "backend/listing_nodes/column_label", :object => @listing_node)
      elsif params[:type] == "comparison"
        @listing_node.condition_operator = params[:comparator]
        @listing_node.condition_value = params[:comparison_value]
        render(:partial => "backend/listing_nodes/comparison", :object => @listing_node)
      elsif params[:type] == "position"
        @listing_node.position = params[:position]
        render(:partial => "backend/listing_nodes/position", :object => @listing_node)
      end
      @listing_node.save
    else
      redirect_to backend_listings_url
    end
  end

  def destroy
    return unless @listing_node = find_and_check
    parent = @listing_node.parent
    @listing_node.reload.destroy
    if request.xhr?
      render(:partial => "backend/listings/reflection", :object => parent)
    else
      redirect_to controller: :listings, action: :edit, id: @listing_node.listing_id
    end
  end

end
