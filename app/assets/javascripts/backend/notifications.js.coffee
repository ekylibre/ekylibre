((E, $) ->
  'use strict'
  E.notifications =
    delay: 10
    read: () ->
      $.ajax
        url: '/backend/notifications/unread'
        dataType: 'json'
        data:
          ago: E.notifications.delay

        success: (data, status, request) ->
          indicator = $("[data-toggle='notifications']").closest('.dropdown.show')
          indicator.attr('title', data.status)

          if data.total_count > 0
            unless indicator.hasClass 'with-notifications'
              indicator.addClass('with-notifications')
          else
            if indicator.hasClass 'with-notifications'
              indicator.attr('title', data.status)
              indicator.removeClass('with-notifications')

          E.notifications.displayMessages(data.unread_messages) if data.unread_messages

        error: (request, status, error) ->
          window.clearInterval(E.notifications.interval)

    displayMessages: (messages) ->
      # for message in messages


  $(document).ready ->
    window.clearInterval(E.notifications.interval)
    E.notifications.interval = window.setInterval(E.notifications.read, E.notifications.delay * 1000)

) ekylibre, jQuery
