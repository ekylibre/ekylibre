(function ($) {
    "use strict";

    // Beehive tab box
    $(document).behave("click", ".box-tab > ul.cell-titles > li > a.cell-title[href]", function () {
        var element = $(this), box = element.closest(".box-tab"), li = element.closest('li');
        if (box !== null) {
            box.find('.cell-titles li.active, .cells .cell.active').removeClass('active');
            li.addClass('active');
            box.find('.cells .cell'+element.attr("href")).addClass('active');
        }
        return false;
    });

    $.fn.raiseContentErrorToCellTitle = function () {
        var cells = $(this);
        cells.each(function () {
            var cell = $(this);
            if (cell.find('.cell-content .error').length > 0) {
                cell.closest('.beehive')
                    .find('.cell-title[href="#' + cell.attr('id') + '"]')
                    .closest('li')
                    .addClass('error');
            }
        });
    };
    $(document).on('page:load', '.beehive .cell', $.fn.raiseContentErrorToCellTitle);
    $(document).ready(function () {
        $(".beehive .cell").raiseContentErrorToCellTitle();
    });
})( jQuery );