module Backend
  module NotificationsHelper
    LEVEL_ICONS = { information: 'info-circle', success: 'check-circle', warning: 'exclamation-circle', error: 'times-circle' }.freeze

    private

      def notification_icon_class(notification)
        "icon-#{LEVEL_ICONS[notification.level.to_sym]}"
      end
  end
end
