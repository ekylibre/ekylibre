// Don't refresh page when <a href='#'> is clicked
$(document).on('turbolinks:click', function (event) {
  if (event.target.getAttribute('href').charAt(0) === '#') {
    event.preventDefault()
  }
})
