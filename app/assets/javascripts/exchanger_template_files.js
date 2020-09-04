(function ($) {
  $(document).ready(function (event) {
    updateTemplateFileLinks();

    $('select#import_nature').change(function () {
      const $link = $(this).closest('form').find('a#template_file_link');
      updateTemplateFileLink($link);
    });
  });

  function updateTemplateFileLinks() {
    $('a#template_file_link').each(function() {
      updateTemplateFileLink($(this));
    });
  };

  function updateTemplateFileLink($link) {
    const $importNatureSelector = $link.closest('form').find('select#import_nature');
    if ($importNatureSelector.children('option:selected').data('template-present')) {
      const exchangerName = $importNatureSelector.children('option:selected').val();
      $link.attr('href', `/backend/exchanger_template_files/${exchangerName}`);
      $link.show();
    } else {
      $link.hide();
    }
  };

})(jQuery);
