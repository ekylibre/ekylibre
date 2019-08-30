((E, $) ->
  'use strict'

  delay = 10
  interval = null

  read = () ->
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

        triggerAnimation(data.unread_notifs)
        displayItems(data.unread_notifs)

      error: (request, status, error) ->
        window.clearInterval(interval)

  triggerAnimation = (notifications) ->
    displayedNotifications = ($('.notification').map ->
      $(this).data('id'))
    .toArray()

    newNotificationReceived = _.find notifications, (n) ->
      !displayedNotifications.includes n.id

    $('.notifications-btn__counter').addClass('notifications-btn__counter--animated') if newNotificationReceived

  displayItems = (notifications) ->
    $('.notifications-menu__item').remove()
    notificationsHtml = notifications.map(template).reverse().join('')
    $('.notifications-menu__placeholder').after(notificationsHtml)

  template = (notification) ->
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
    interval = window.setInterval(read, delay * 1000) if interval == null

) ekylibre, jQuery
