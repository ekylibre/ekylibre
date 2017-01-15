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
  class NotificationsController < Backend::BaseController
    def index
      if params[:mode] == 'unread'
        @notifications = current_user.unread_notifications.where('created_at >= ?', Time.now - params[:ago].to_f)
        global_count = current_user.unread_notifications.count
        response = {
          count: global_count,
          status: :x_notifications.tl(count: global_count),
          new_messages: @notifications.collect(&:human_message)
        }
        render json: response.to_json
      else
        @notifications = current_user.unread_notifications.order(created_at: :desc)
      end
    end

    def show
      notification = find_and_check
      return unless notification
      notification.read!
      if notification.target_url
        redirect_to notification.target_url
      elsif notification.target
        target = notification.target
        redirect_to(controller: target.class.model_name.plural, action: :show, id: target.id)
      else
        redirect_to action: :index
      end
    end

    def destroy
      if params[:id]
        notification = find_and_check
        return unless notification
        notification.read!
      else
        current_user.unread_notifications.find_each(&:read!)
      end
      redirect_to params[:redirect] || { action: :index }
    end
  end
end
