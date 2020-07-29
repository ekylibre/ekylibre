(function ($) {
  function registerLandParcelButtonClickListener() {
    $('#generate-land-parcel-btn').on('click', function(){
      $.ajax({
        url: 'controller_helpers/activity_production_creations/new'
      })
      .then(data => {
        const title = I18n.t('front-end.land_parcel.create_modal.title')
        const html = `
          <div class="modal fade" id="land-parcel-modal" role="dialog">
            <div class="modal-dialog modal-dialog-centered">
              <div class="modal-content">
                <div class="modal-header modal-header--document">
                  <button class="close" data-dismiss="modal">
                    <i class="icon icon-destroy"></i>
                  </button>
                  <b class="modal-title">${title}</b>
                </div>
                <div class="modal-body">
                  ${data}
                </div>
              </div>
            </div>
          </div>
        `
        $(document.body).append($(html))
        $modal = $("#land-parcel-modal").modal()
        $modal.on('hidden.bs.modal', function() { // Supprimer la modale au lieu de la cacher
          $(this).remove()
        })
        $modal.on('ajax:error', function(event, xhr, status, error) {
          // insert the failure message inside the "#account_settings" element
          $modal.find('.modal-body').html(xhr.responseText)
        });
      })
    })
  }

  document.addEventListener('DOMContentLoaded', registerLandParcelButtonClickListener)
  document.addEventListener('page:load', registerLandParcelButtonClickListener)
})(jQuery)
