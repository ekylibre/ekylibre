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

function isGet(options) {
  let {method = 'GET'} = options

  return method === 'GET'
}

function buildUrl(urlStr, params){
  const url = new URL(urlStr, window.location.href)
  Object.keys(params).forEach(key => url.searchParams.append(key, params[key]))

  return url
}

export function ajax(options) {
  let {url, data = {}, ...opt} = options
  if (isGet(options)) {
    url = buildUrl(url, data)
  } else {
    opt = {...opt, data}
  }

  return customFetch(url, opt)
}

ajax.json = options => ajax(options).then(parseJSON)
ajax.text = options => ajax(options).then(responseText)
ajax.html = ajax.text
