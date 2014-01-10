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

/*
    $.equalizeCells = function (group) {
        var height, targets = group.find('.cell .cell-inner .cell-content');
        console.log("equalize");
        height = Math.max.apply(this, targets.map(function () {
            return $(this).height();
        }));
        targets.height(height);
    };

    $.fn.equalize = function () {
        $(this).each(function () {
            $.equalizeCells($(this));
        });
    };

    $.equalizeAllCells = function () {
        $('.cells').equalize();
    };

    $(document).on('page:load resize', $.equalizeAllCells);
    $(document).on('cell:load', '*[data-cell]', function () {
        var cell = $(this);
        cell.height("auto");
        window.setTimeout(function () {
            cell.closest('.cells').equalize();
        }, 300);
    });
    $(document).ready(function () {
        $.equalizeAllCells();
    });
*/
})( jQuery );