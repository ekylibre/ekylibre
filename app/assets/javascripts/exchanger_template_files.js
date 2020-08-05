(function ($) {
  $(document).ready(function (event) {
    updateTemplateFileLink();

    $("select#import_nature").change(function () {
      updateTemplateFileLink();
    });
  });

  const updateTemplateFileLink = () => {
    const $link = $("a#template_file_link");
    const $importNatureSelector = $("select#import_nature");
    if ($importNatureSelector.children("option:selected").data("templatePresent")) {
      const exchangerName = $importNatureSelector
        .children("option:selected")
        .val();
      $link.attr("href", `/backend/exchanger_template_files/${exchangerName}`);
      $link.show();
    } else {
      $link.hide();
    }
  };
})(jQuery);
