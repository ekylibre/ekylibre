export function checkStatus(response) {
  if (response.status >= 200 && response.status < 300) {
    return response
  } else {
    var error = new Error(response.statusText)
    error.response = response
    throw error
  }
}

export function parseJSON(response) {
  return response.json()
}

export function responseText(response) {
  return response.text()
}

export function customFetch(url, options) {
  return fetch(url, options)
    .then(checkStatus)
}

export function ajax(options) {
  let {url, ...opt} = options

  return customFetch(url, opt)
}
ajax.json = options => ajax(options).then(parseJSON)
ajax.text = options => ajax(options).then(responseText)
ajax.html = ajax.text
