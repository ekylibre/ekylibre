# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2008-2013 Brice Texier
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

class Backend::AffairsController < BackendController

  list do |t|
    t.column :debit, :currency => true
    t.column :credit, :currency => true
    t.column :closed
  end

  def index
  end

  def select
    return unless @affair = find_and_check
    @third = Entity.where(:id => params[:third_id]).first
    @deals = params[:deal_type].to_s.pluralize
    @deal_class = @deals.classify.constantize
    @third_column = @deal_class.reflections[@deal_class.affairable_options[:third]].foreign_key
  end

  def attach
    return unless @affair = find_and_check
    deal = params[:deal_type].camelcase.constantize.where(:id => params[:deal_id]).first
    @affair.attach(deal)
    redirect_to params[:redirect] || {:controller => params[:deal_type].pluralize, :action => :show, :id => params[:deal_id]}
  end

  def detach
    return unless @affair = find_and_check
    deal = params[:deal_type].camelcase.constantize.where(:id => params[:deal_id]).first
    @affair.detach(deal)
    redirect_to params[:redirect] || {:controller => params[:deal_type].pluralize, :action => :show, :id => params[:deal_id]}
  end

end
