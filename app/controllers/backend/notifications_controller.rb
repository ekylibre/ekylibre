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
    include NotificationsHelper

    def index
      @unread_notifications = current_user.unread_notifications.order(created_at: :asc)
      if params[:mode] == :unread
        unread_notifs = @unread_notifications.map { |notif|
          { id: notif.id,
            message: notif.human_message,
            time: ActionController::Base.helpers.distance_of_time_in_words_to_now(notif.created_at),
            url: backend_notification_path(notif),
            icon: notification_icon_class(notif),
            created_at: notif.created_at
          }
        }
        response = {
          total_count: @unread_notifications.count,
          unread_notifs: unread_notifs
        }
        render json: response.to_json
      else
        @notifications = Notification.order(created_at: :desc)
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
