# -*- coding: utf-8 -*-
# == License
# Ekylibre ERP - Simple agricultural ERP
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

class Backend::SubscriptionNaturesController < BackendController
  manage_restfully nature: "SubscriptionNature.nature.default_value".c, entity_link_direction: "SubscriptionNature.entity_link_direction.default_value".c

  unroll

  list(:children => :product_nature_categories) do |t|
    t.column :name, url: {id: 'nil'.c, action: :index, controller: :subscriptions, nature_id: "RECORD.id".c}
    t.column :nature, children: false
    t.column :actual_number, children: false
    t.column :reduction_percentage, children: false
    t.action :increment, method: :post, if: :quantity?
    t.action :decrement, method: :post, if: :quantity?
    t.action :edit
    t.action :destroy, if: :destroyable?
  end

  def show
    return unless subscription_nature = find_and_check
    redirect_to backend_subscriptions_url(nature_id: subscription_nature.id)
  end

  def decrement
    return unless subscription_nature = find_and_check
    subscription_nature.decrement!(:actual_number)
    notify_success(:new_actual_number, :actual_number => subscription_nature.actual_number)
    redirect_to_back
  end

  def increment
    return unless subscription_nature = find_and_check
    subscription_nature.increment!(:actual_number)
    notify_success(:new_actual_number, :actual_number => subscription_nature.actual_number)
    redirect_to_back
  end

end
