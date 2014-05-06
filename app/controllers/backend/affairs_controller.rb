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
  manage_restfully only: [:index, :show]

  list do |t|
    t.column :number, url: true
    t.status
    t.column :debit, currency: true
    t.column :credit, currency: true
    t.column :closed, hidden: true
    t.column :closed_at
    t.column :third, url: true
    t.column :deals_count, hidden: true
    t.column :journal_entry, url: true
  end

  def select
    return unless @affair = find_and_check
    @deal_model = params[:deal_type].camelcase.constantize
    @third = Entity.find_by(id: params[:third_id]) if params[:third_id]
    @third ||= @affair.third
  end

  def attach
    return unless @affair = find_and_check
    if deal = params[:deal_type].camelcase.constantize.find_by(id: params[:deal_id]) rescue nil
      deal.deal_with! @affair
      # @affair.attach(deal)
      redirect_to params[:redirect] || {controller: deal.class.name.tableize, action: :show, id: deal.id}
    else
      notify_error(:cannot_find_deal_to_attach)
      redirect_to params[:redirect] || {controller: @affair.originator_type.tableize, action: :show, id: @affair.originator_id}, status: :not_found
    end
  end

  def detach
    return unless @affair = find_and_check
    if deal = params[:deal_type].camelcase.constantize.find_by(id: params[:deal_id]) rescue nil
      deal.undeal! @affair
      # @affair.detach(deal)
      redirect_to params[:redirect] || {controller: deal.class.name.tableize, action: :show, id: deal.id}
    else
      notify_error(:cannot_find_deal_to_detach)
      redirect_to params[:redirect] || {controller: @affair.originator_type.tableize, action: :show, id: @affair.originator_id}, status: :not_found
    end
  end


  def finish
    return unless @affair = find_and_check
    unless @affair.finish
      notify_error :cannot_finish_affair
    end
    redirect_to(params[:redirect] || {controller: @affair.originator_type.tableize, action: :show, id: @affair.originator_id})
  end

end
