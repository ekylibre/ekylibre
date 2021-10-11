module Backend
  module NotificationRenderingHelper
    def notification_tag(mode, messages = nil)
      ActiveSupport::Deprecation.warn "`notification_tag` is deprecated, use `flash_message_tag` or `flash_messages_tags` instead"
      unless messages
        if flash[:notifications].is_a?(Hash) && flash[:notifications][mode.to_s].is_a?(Array)
          messages = flash[:notifications][mode.to_s]
        end
      end
      Array(messages).map do |message|
        flash_message_tag(mode, message)
      end.reduce(''.html_safe, &:+)
    end

    def flash_message_tag(mode, message, html: false)
      if html
        message = content_tag(:div, message, class: :notification_body)
      else
        message = content_tag(:p, text_to_html_message(message), class: :notification_body)
      end

      flash_html_message_tag(mode, message)
    end

    def flash_messages_tags(mode, messages, html: false)
      messages
        .map { |message| flash_message_tag(mode, message, html: html) }
        .reduce(''.html_safe, &:+)
    end

    def notifications_tag
      %i[error warning success information].flat_map do |mode|
        fetch_notifications_tags(mode.to_s)
      end.reduce(''.html_safe, &:+)
    end

    private

      def text_to_html_message(message)
        h(message).gsub(/\n/, '<br/>').html_safe
      end

      def flash_html_message_tag(mode, html)
        content_tag :div, { class: "flash #{mode}", data: { alert: true } } do
          content_tag(:a, "&times;".html_safe, { class: :close, href: '#' }) +
            content_tag(:div, '', { class: :icon }) +
            content_tag(:div, { class: :message }) do
              content_tag(:h3, mode.t(scope: 'notifications.levels').html_safe) + html
            end
        end
      end

      def fetch_notifications_tags(mode)
        [*html_tags(mode), *text_tags(mode)]
      end

      def html_tags(mode)
        notifications = flash[:notifications] || {}

        messages = notifications.fetch("#{mode}_html", []).map(&:html_safe)

        flash_messages_tags(mode, messages, html: true)
      end

      def text_tags(mode)
        notifications = flash[:notifications] || {}

        flash_messages_tags(mode, notifications.fetch(mode, []))
      end
  end
end
