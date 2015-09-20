((E, $) ->
  'use strict'
  E.notifications =
    delay: 60
    read: () ->
      $.ajax
        url: '/backend/notifications/unread'
        dataType: 'json'
        data:
          ago: E.notifications.delay
        success: (data, status, request) ->
          # Update indicator state
          indicator = $('*[data-toggle="notifications"]')
          indicator.attr('title', data.status)
          if data.count > 0
            unless indicator.hasClass 'with-notifications'
              indicator.addClass('with-notifications')
          else
            if indicator.hasClass 'with-notifications'
              indicator.attr('title', data.status)
              indicator.removeClass('with-notifications')
          # Show notification via browser
          if data.new_messages and window.Notification isnt undefined
            for message in data.new_messages
              E.notifications.notify(message)
        error: (request, status, error) ->
          window.clearInterval(E.notifications.interval)

    notify: (message) ->
      if Notification.permission is "granted"
        # If it's okay let's create a notification
        notification = new Notification(message)

      # Otherwise, we need to ask the user for permission
      else if Notification.permission isnt 'denied'
        notif = (permission) ->
          # If the user accepts, let's create a notification
          if permission is "granted"
            new Notification(message)
        Notification.requestPermission(notif)

  $(document).ready ->
    if window.Notification is undefined
      console.warn("Your browser does not support notifications")
    else
      if Notification.permission isnt 'denied'
        Notification.requestPermission

    window.clearInterval(E.notifications.interval)
    E.notifications.interval = window.setInterval(E.notifications.read, E.notifications.delay * 1000)

) ekylibre, jQuery
