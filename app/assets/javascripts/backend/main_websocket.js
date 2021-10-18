//= require action_cable
(function (E, $) {
  E.onDomReady(function () {
    if (!ActionCable.main_consumer){
      user_email = $("#ws-att").data("current-account");
      subscribe_main_ws(user_email);
    }
  });

  /**
   * Creates ActionCable connection & bind to user-Main-channel
   */
  function subscribe_main_ws(user_email) {
    consumer = ActionCable.createConsumer('/cable');
    ActionCable.main_consumer = consumer
    subscription = consumer.subscriptions.create({
      channel: 'MainChannel',
      roomId: user_email
    }, {
    received: function(data) {
        switch(data.event) {
          case 'update_job_over':
            update_job_over();
            break;
          case 'new_notification':
            update_notifications();
        }
    }
    });
  }

  function update_job_over(){
    $('.update-job').attr('disabled', false);
    $('.bqspinner').hide();
  };

  function update_notifications(){
    E.ajax.json({
      url: '/backend/notifications/unread'
    }).then((function(_this) {
      return function(data) {
        var $counter, $placeholder;
        $counter = $('.notifications-btn__counter');
        $placeholder = $('.notifications-menu__placeholder');
        $counter.removeClass('notifications-btn__counter--animated');
        $placeholder.toggle(data.total_count <= 0);
        $counter.toggleClass('notifications-btn__counter--with-notifications', data.total_count > 0);
        if (data.total_count > 0) {
          $counter.text(data.total_count);
        } else {
          $counter.text('');
        }
        triggerAnimation(data.unread_notifs);
        return displayItems(data.unread_notifs);
      };
    })(this))["catch"]((function(_this) {
      return function(error) {
        console.log("unable to display latest notification");
      };
    })(this));
  };

  triggerAnimation = function(notifications) {
    var displayedNotifications, newNotificationReceived;
    displayedNotifications = $('.notification').map(function() {
      return $(this).data('id');
    }).toArray();
    newNotificationReceived = _.find(notifications, function(n) {
      return !displayedNotifications.includes(n.id);
    });
    if (newNotificationReceived) {
      $('.notifications-btn__counter').addClass('notifications-btn__counter--animated');
      window.setTimeout(removeAnimation, 2500);
    }
  };

  removeAnimation = function(notifications) {
    $('.notifications-btn__counter').removeClass('notifications-btn__counter--animated');
  }
  displayItems = function(notifications) {
    var notificationsHtml;
    $('.notifications-menu__item').remove();
    notificationsHtml = notifications.map(template).reverse().join('');
    notifications.forEach((function(_this) {
      return function(notification) {
        E.notification.notify(notification);
      };
    })(this));
    return $('.notifications-menu__placeholder').after(notificationsHtml);
  };
  template = function(notification) {
    return "<a href='" + notification.url + "' class='notifications-menu__item'> <div class='notification' data-id='" + notification.id + "'> <div class='notification__state text-center'> <i class='icon " + notification.icon + "'></i> </div> <div class='notification__message'> " + notification.message + " </div> <div class='notification__time'> " + notification.time + " </div> </div> </a>";
  };
  return E.notification.setup({
    icon: "<%= image_url('icon/ipad.png') %>"
  });

})(ekylibre, jQuery);