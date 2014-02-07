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

class Backend::InterfacersController < BackendController

  # Saves the state of the side bar
  def toggle_side
    # Explicit conversion
    session[:side] = (params[:splitted] == "1" ? false : true)
    render :text => ''
  end

  # Saves the last selected tab in a tabbox
  def toggle_tab
    session[:tabbox] ||= {}
    session[:tabbox][params['id']] = params['index']
    render :text => nil
  end

  # Saves the view mode
  def toggle_view_mode
    session[:view_mode] = params[:mode]
    render :text => ''
  end

  # TODO: Manage options in role and add watch dog to ensure that autocomplete must be used in rights with parameters
  def autocomplete

  end

  def select_options
    options = [:source, :filter, :model, :id, :label, :include_blank, :selected].inject({}) do |hash, key|
      hash[key] = params[key] if params.has_key?(key)
      hash
    end
    respond_to do |format|
      format.html { render :inline => '<%=options_for_unroll(@options)-%>' }
    end
  end

  def search_for
  end



  def unroll
    @options = [:source, :filter, :model, :id, :label, :include_blank, :selected].inject({}) do |hash, key|
      hash[key] = params[key] if params.has_key?(key)
      hash
    end
    render :inline => '<%=options_for_unroll(@options)-%>'
  end


  # Returns the new list for a "dynamic select" using helper options_for_unroll
  def unroll_options
    @options = {}
    for x in [:reflection, :order, :label, :include_blank]
      @options[x] = params[x]
    end
    render :inline => '<%=options_for_select(options_for_unroll(@options), params[:selected].to_i)-%>'
  end

  def product_trackings
    return unless @product = find_and_check(:product_natures, params[:product_id])
    render :inline => "<%=options_for_select([['---', '']]+@product.trackings.collect{|x| [x.name, x.id]})-%>", :layout => false
  end

  def product_units
    return unless @product = find_and_check(:product_natures, params[:product_id])
    render :inline => "<%=options_for_select(@product.units.collect{|x| [x.name, x.id]})-%>", :layout => false
  end


  def self.available_prices_conditions
    code = ""
    code << "c=['#{ProductPriceTemplate.table_name}.active=? AND #{ProductNature.table_name}.active=?', true, true]\n"
    code << "if session[:current_currency]\n"
    code << "  c[0] << ' AND currency=?'\n"
    code << "  c << session[:current_currency]\n"
    code << "end\n"
    return code
  end

end
