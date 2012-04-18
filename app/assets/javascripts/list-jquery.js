/* -*- Mode: Javascript; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2; coding: utf-8 -*- */
/*jslint browser: true */
/* List Javascript Inobtrusive Support for jQuery */

(function($) {

    $.behave(".list .pagination[data-list] a", "load", function(event) {
        $(this).attr("data-remote", "true");
        $(this).attr("data-list-update", $(this).closest(".pagination[data-list]").data("list"));
    });

    $.behave("a[data-toggle-column]", "click", function(event) {
        var element = $(this), columnId = element.data('toggle-column');
        var column = $('#'+columnId);
        var className = column.data("cells-class");
        if (className === null) { className = columnId; }
        var search = '.'+className;
        var visibility = '';
        if (column.hasClass("hidden")) {
            $(search).removeClass("hidden");
            column.removeClass("hidden");
            element.removeClass("unchecked");
            element.addClass("checked");
            visibility = 'shown';
        } else {
            $(search).addClass("hidden");
            column.addClass("hidden");
            element.removeClass("checked");
            element.addClass("unchecked");
            visibility = 'hidden';
        }
        var url = element.attr("href")
        if (url !== null) {
            $.ajax(url, {data: {visibility: visibility} });
        }
        return false;
    });


    $.behave("select[data-per-page]", "change", function(event) {
        var element = $(this), url = element.data('per-page');
        if (url !== null) {
            var update = element.data('update'), options = {data: {per_page: element.value}};
            if (update !== null) {
                options.success = function (data, status, xhr) {
                    $('#'+update).html(data);
                }
            }
            $.ajax(url, options);
        }
        return false;
    });

    $.behave("a[data-remote-update]", "click", function(event, element) {
        var url = element.attr('href');
        var method = element.data('method') || 'get';
        var update = element.data('remote-update');
        $.ajax(url, {
            method: method,
            success: function (data, status, xhr) {
                $('#'+update).html(data); 
            }
        });
        return false;
    });

    $.behave("a[data-list-update]", "ajax:success", function(event, data, status, xhr) {
        $($(this).data('list-update')).html(data);
    });

})(jQuery);
