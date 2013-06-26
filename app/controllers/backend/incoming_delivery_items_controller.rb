# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2013 Brice Texier
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

class Backend::IncomingDeliveryItemsController < BackendController

  def new
    if request.xhr? and params[:nature_id]
      return unless nature = find_and_check(:product_nature, params[:nature_id])
      @incoming_delivery_item = IncomingDeliveryItem.new(:natue => nature)
      render :partial => "form", :locals => {:nature => nature}
    else
      head :forbidden
    end
  end


end
