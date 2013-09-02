/* -*- Mode: Javascript; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2; coding: utf-8 -*- */
/*jslint browser: true */
/* List Javascript Inobtrusive Support for jQuery */

(function ($) {
    "use strict";

    $.ActiveList = {};

    // Main function which reload table with specified data parameters
    $.ActiveList.refresh = function (element, new_parameters) {
        var source, parameters, url;
        // element = $(element);
        source = element.closest('div[data-list-source]');
        parameters = {
            sort: source.data("list-sort-by"),
            dir: source.data("list-sort-dir"),
            page: source.data("list-current-page"),
            per_page: source.data("list-page-size")
        };
        $.extend(parameters, new_parameters);
        url = source.data('list-source');
        $.ajax(url, {
            data: parameters,
            dataType: "html",
            success: function (data, status, request) {
                source.replaceWith(data);
                return true;
            }
        });
        return false;
    };


    $.ActiveList.moveToPage = function (element, page) {
        var page_attr;
        // element = $(element);
        if (page === undefined || page === null || page === '') {
            page = element.data('list-move-to-page');
        }
        if (page === undefined || page === null || page === '') {
            alert("Cannot define which page to load: "+page);
        }
        if (isNaN(page)) {
            page_attr = page;
            page = element.attr(page_attr);
            if (isNaN(page)) {
                alert("Cannot define which page to load with attribute " + page_attr + ": "+page);
            }
        }
        $.ActiveList.refresh(element, {page: page});
        return false;
    };


    // Sort by one column
    $(document).on('click', 'div[data-list-source] th[data-list-column][data-list-column-sort]', function(event) {
        var element = $(this);
        $.ActiveList.refresh(element, {
            sort: element.data('list-column'),
            dir: element.data('list-column-sort')
        });
        return false;       
    });


    // Change number of item per page
    $(document).on('click', 'div[data-list-source] li[data-list-change-page-size]', function(event) {
        var element = $(this), per_page=element.data('list-change-page-size');
        if (isNaN(per_page)) {
            alert("@list-change-page-size attribute is not a number: "+per_page);
        } else {
            $.ActiveList.refresh(element, {per_page: per_page});
        }
        return false;
    });


    // Toggle visibility of a column
    $(document).on('click', 'div[data-list-source] li[data-list-toggle-column]', function(event) {
        var element = $(this), columnId, column, className, search, visibility = '', url, source;
        columnId = element.data('list-toggle-column');
        source = element.closest('div[data-list-source]');
        column = source.find('th[data-list-column="'+columnId+'"]');
        //$('#'+columnId);
        className = column.data("list-column-cells");
        if (className === null) { 
            className = columnId;
        }
        search = '.'+className;
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
        url = source.data('list-source');
        $.ajax(url, {
            dataType: "html",
            data: {
                visibility: visibility,
                column: columnId
            }
        });
        return false;
    });

    // Change page of table on link clicks
    $(document).on('click', 'div[data-list-source] a[data-list-move-to-page]', function(event) {
        $.ActiveList.moveToPage($(this));
        return false;
    });

    // Change page of table on input changes
    $(document).on('change', 'div[data-list-source] input[data-list-move-to-page]', function(event) {
        $.ActiveList.moveToPage($(this));
        return false;
    });


    // Adds title attribute based on link name
    $(document).on('hover', 'div[data-list-source] tbody tr td.act a', function (event) {
	      var element = $(this), title = element.attr('title');
	      if (title === null || title === undefined) {
	          element.attr('title', element.html());
	      }
    });

})(jQuery);
