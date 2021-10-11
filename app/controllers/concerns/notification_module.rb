module NotificationModule
  extend ActiveSupport::Concern

  included do
    include ScopedTranslationHelper
    protected :stl, :with_i18n_scope
  end

  protected

    def notify(message, nature = :information, mode = :next, default: [], html: false, **options)
      options = {
        **options,
        default: [*default, message.to_s.humanize],
      }

      nature = nature
      nature = "#{nature.to_s}_html" if html
      nature = nature.to_sym

      notification_message = translate_message_if_necessary(message, options)

      notistore = get_store(mode)
      return if notistore[:notifications]&.[](nature.to_s)&.find { |n| n == notification_message }&.present?

      notifications = (notistore[:notifications] || {}).symbolize_keys
      notistore[:notifications] = { **notifications, nature => [*notifications.fetch(nature, []), notification_message] }.stringify_keys
    end

    def notify_error(message, options = {})
      notify(message, :error, **options)
    end

    def notify_warning(message, options = {})
      notify(message, :warning, **options)
    end

    def notify_success(message, options = {})
      notify(message, :success, **options)
    end

    def notify_now(message, options = {})
      notify(message, :information, :now, **options)
    end

    def notify_error_now(message, options = {})
      notify(message, :error, :now, **options)
    end

    def notify_warning_now(message, options = {})
      notify(message, :warning, :now, **options)
    end

    def notify_success_now(message, options = {})
      notify(message, :success, :now, **options)
    end

    def has_notifications?(nature = nil)
      if flash[:notifications].is_a?(Hash)
        if nature.nil?
          flash[:notifications].keys.any? { |n| has_nature_notification?(n) }
        else
          has_nature_notification?(nature)
        end
      else
        false
      end
    end

  private

    def has_nature_notification?(nature)
      flash[:notifications][nature].is_a?(Array) && flash[:notifications][nature].any?
    end

    def translate_message_if_necessary(message, options)
      if message.nil?
        nil
      elsif message.is_a? String
        message
      else
        ScopedTranslationHelper.with_i18n_scope :notifications, :messages, replace: true do
          stl message, **options
        end
      end
    end

    def get_store(mode)
      mode == :now ? flash.now : flash
    end
end
