(function (E, $) {

  $(document).on("change", "#workers-list td > input[data-list-selector], #workers-list th.list-selector", (e) => {
    var checked = $('#workers-list td > input[data-list-selector]:checked').toArray()
    if (checked.length > 1){
      $('.create-workers-group').show()
      ids = $.map(checked, function(elem){
        return elem.value 
      })
      var url = `/backend/worker_groups/new?worker_ids=${ids}`
      $('.create-worker-group-btn').attr('href', url)
    } else {
      $('.create-workers-group').hide()
    }
  });
})(ekylibre, jQuery);
