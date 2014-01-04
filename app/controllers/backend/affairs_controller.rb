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
    t.column :debit, currency: true
    t.column :credit, currency: true
    t.column :closed, hidden: true
    t.column :closed_at
    t.column :third, url: true
    t.column :journal_entry, url: true
  end

  def index
  end

  def select
    return unless @affair = find_and_check
    @third = Entity.find_by(id: params[:third_id])
    @deals = params[:deal_type].to_s.pluralize
    @deal_class = @deals.classify.constantize
    @third_column = @deal_class.reflections[@deal_class.affairable_options[:third]].foreign_key
  end

  def attach
    return unless @affair = find_and_check
    if deal = params[:deal_type].camelcase.constantize.find_by(id: params[:deal_id])
      @affair.attach(deal)
    end
    redirect_to params[:redirect] || {:controller => params[:deal_type].pluralize, :action => :show, :id => params[:deal_id]}
  end

  def detach
    return unless @affair = find_and_check
    if deal = params[:deal_type].camelcase.constantize.find_by(id: params[:deal_id])
      @affair.detach(deal)
    end
    redirect_to params[:redirect] || {:controller => params[:deal_type].pluralize, :action => :show, :id => params[:deal_id]}
  end

end
