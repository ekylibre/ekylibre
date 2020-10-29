let defaults = {}
let lastSeen = null
const LAST_SEEN_KEY = "notification.lastSeen"

export function setup(options = {}) {
  defaults = options

  return new Promise((resolve, reject) => {
    if (window.Notification && window.localStorage) {
      return Notification.requestPermission(function (status) {
        // Allow to use Notification.permission with Chrome/Safari
        if (Notification.permission !== status) {
          Notification.permission = status
        }
        resolve(status)
      })
    } else {
      reject(new Error("The browser does not support notifications."))
    }
  }).then(() => {
    lastSeen = new Date(localStorage.getItem(LAST_SEEN_KEY)) || Date.now()
  })
}

function enabled() {
  return window.Notification && window.Notification.permission === 'granted'
}

function doNotify(title, message, options = {}) {
  const {onclick, ...rest} = options
  if (enabled()) {
    const notification = new Notification(title, {...defaults, ...rest, body: message})

    if (onclick)
      notification.onclick = onclick

    return notification
  } else {
    return false
  }
}

export function notify(notif, options = {}) {
  const d = new Date(notif.created_at)
  if (!lastSeen || d > lastSeen) {
    lastSeen = d
    localStorage.setItem(LAST_SEEN_KEY, d.toISOString())
    return doNotify("Ekylibre", notif.message, options)
  } else {
    return false
  }
}
