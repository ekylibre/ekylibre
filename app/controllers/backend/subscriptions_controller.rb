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

module Backend
  class SubscriptionsController < Backend::BaseController
    manage_restfully(
      # address_id: 'EntityAddress.find_by(entity_id: params[:subscriber_id]).id rescue nil'.c,
      # nature_id: 'SubscriptionNature.first.id rescue 0'.c,
      quantity: 1,
      started_on: 'Time.zone.today'.c,
      stopped_on: 'Time.zone.today + 1.year - 1.day'.c,
      t3e: {
        nature: 'RECORD.nature_name'.c,
        start: 'RECORD.started_on.l'.c,
        finish: 'RECORD.stopped_on.l'.c
      }
    )
    unroll

    def self.subscriptions_conditions
      code = ''
      # COALESCE(#{Sale.table_name}.state NOT INsale_id, 0) NOT IN (SELECT id FROM #{Sale.table_name} WHERE state NOT IN ('invoice', 'order'))
      code << "conditions = ['1=1']\n"
      code << "unless params[:nature_id].to_i.zero?\n"
      code << "  conditions[0] += \" AND #{Subscription.table_name}.nature_id = ?\"\n"
      code << "  conditions << params[:nature_id].to_i\n"
      code << "end\n"
      code << "if params[:subscribed_on].to_s =~ /\A\d\d\d\d\-\d\d\-\d\d\z/.nil?\n"
      code << "  conditions[0] += \" AND ? BETWEEN #{Subscription.table_name}.started_on AND #{Subscription.table_name}.stopped_on\"\n"
      code << "  conditions << params[:subscribed_on]\n"
      code << "end\n"
      code << "conditions\n"
      code.c
    end

    list(conditions: subscriptions_conditions, order: { started_on: :desc }, line_class: "(RECORD.disabled? ? 'disabled' : RECORD.active? ? 'success' : '') + (RECORD.suspended ? ' squeezed' : '')".c) do |t|
      t.action :edit
      t.action :renew, method: :post, if: 'current_user.can?(:write, :sales) && RECORD.renewable?'.c
      t.action :suspend, method: :post, if: :suspendable?
      t.action :takeover, method: :post, if: :suspended
      t.action :destroy, if: :destroyable_by_user?
      t.column :number, url: true
      t.column :subscriber, url: true
      t.column :coordinate, through: :address, url: true
      # t.column :product_nature
      t.column :quantity
      t.column :sale, url: true
      t.column :started_on
      t.column :stopped_on
    end

    def renew
      @subscription = find_and_check
      unless @subscription.renewable?
        notify_error :subscription_is_not_renewable
        redirect_to params[:redirect] || { action: :show, id: @subscription.id }
        return
      end
      unless current_user.can?(:write, :sales)
        notify_error :access_denied
        redirect_to params[:redirect] || { action: :show, id: @subscription.id }
        return
      end
      redirect_to(@subscription.renew_attributes.merge(controller: :sales, action: :new))
    end

    def suspend
      @subscription = find_and_check
      @subscription.suspend
      redirect_to params[:redirect] || { action: :show, id: @subscription.id }
    end

    def takeover
      @subscription = find_and_check
      @subscription.takeover
      redirect_to params[:redirect] || { action: :show, id: @subscription.id }
    end
  end
end
