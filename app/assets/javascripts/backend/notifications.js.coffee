((E, $) ->
  'use strict'
  E.notifications =
    delay: 10
    read: () ->
      $.ajax
        url: '/backend/notifications/unread'
        dataType: 'json'

        success: (data, status, request) ->
          $counter = $('.notifications-btn__counter')
          $placeholder = $('.notifications-menu__placeholder')

          $counter.removeClass('notifications-btn__counter--animated')
          $placeholder.toggle(!data.total_count > 0)
          $counter.toggleClass('notifications-btn__counter--with-notifications', data.total_count > 0)
          if data.total_count > 0 then $counter.text(data.total_count) else $counter.text('')

          E.notifications.triggerAnimation(data.unread_notifs)
          E.notifications.displayItems(data.unread_notifs)

        error: (request, status, error) ->
          window.clearInterval(E.notifications.interval)

    triggerAnimation: (notifications) ->
      displayedNotifications = $('.notification').map ->
        $(this).data('id')
      .toArray()

      for notification in notifications
        unless displayedNotifications.includes notification.id
          $('.notifications-btn__counter').addClass('notifications-btn__counter--animated')
          break

    displayItems: (notifications) ->
      $('.notifications-menu__item').remove()
      for notification in notifications
        $('.notifications-menu__placeholder').after(E.notifications.template notification)

    template: (notification) ->
      "<a href='#{notification.url}' class='notifications-menu__item'>
         <div class='notification' data-id='#{notification.id}'>
           <div class='notification__state text-center'>
             <i class='icon #{notification.icon}'></i>
           </div>
           <div class='notification__message'>
             #{notification.message}
           </div>
           <div class='notification__time'>
             #{notification.time}
           </div>
         </div>
       </a>"


  $(document).ready ->
    window.clearInterval(E.notifications.interval)
    E.notifications.interval = window.setInterval(E.notifications.read, E.notifications.delay * 1000)

) ekylibre, jQuery
