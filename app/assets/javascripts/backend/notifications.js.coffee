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
          $counter = $('.notifications-btn__counter')

          if data.total_count > 0
            $counter.addClass('notifications-btn__counter--with-notifications')
            $counter.text(data.total_count)
          else
            $counter.removeClass('notifications-btn__counter--with-notifications')
            $counter.text('')

          E.notifications.displayItems(data.unread_notifs) if data.unread_notifs

        error: (request, status, error) ->
          window.clearInterval(E.notifications.interval)


    displayItems: (notifications) ->
      # for message in messages


    template: (notification) ->
      "<a href='#{notification.url}' class='notifications-menu__item'>
         <div class='notification'>
           <div class='notification__state text-center'>
             <i class='icon #{notification.icon}'></i>
           </div>
           <div class='notification__message'>
             #{notification.message}
           </div>
           <div class='notification__time'>
             #{notification.created_at}
           </div>
         </div>
       </a>"


  $(document).ready ->
    window.clearInterval(E.notifications.interval)
    E.notifications.interval = window.setInterval(E.notifications.read, E.notifications.delay * 1000)

) ekylibre, jQuery
