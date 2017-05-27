# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2013 Brice Texier
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

module Backend
  class AffairsController < Backend::BaseController
    manage_restfully only: %i[index show], subclass_inheritance: true

    unroll

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
      if deal = begin
                  params[:deal_type].camelcase.constantize.find_by(id: params[:deal_id])
                rescue
                  nil
                end
        deal.deal_with! @affair
        # @affair.attach(deal)
        redirect_to params[:redirect] || { controller: deal.class.name.tableize, action: :show, id: deal.id }
      else
        notify_error(:cannot_find_deal_to_attach)
        redirect_to_best_page
      end
    end

    def detach
      return unless @affair = find_and_check
      if deal = begin
                  params[:deal_type].camelcase.constantize.find_by(id: params[:deal_id])
                rescue
                  nil
                end
        deal.undeal! @affair
        # @affair.detach(deal)
        redirect_to params[:redirect] || { controller: deal.class.name.tableize, action: :show, id: deal.id }
      else
        notify_error(:cannot_find_deal_to_detach)
        redirect_to_best_page
      end
    end

    def detach_gaps
      return unless @affair = find_and_check
      @affair.gaps.each { |g| g.undeal! @affair }
      redirect_to params[:redirect] || redirect_to_best_page
    end

    def finish
      return unless @affair = find_and_check
      notify_error :cannot_finish_affair unless @affair.finish
      redirect_to_best_page
    end

    protected

    def redirect_to_best_page(affair = nil)
      affair ||= @affair
      url = params[:redirect]
      unless url
        originator = affair.originator
        url = if originator
                { controller: originator.class.name.tableize, action: :show, id: originator.id }
              else
                { controller: affair.class.name.tableize, action: :show, id: affair.id }
              end
      end
      redirect_to params[:redirect] || url
    end
  end
end
