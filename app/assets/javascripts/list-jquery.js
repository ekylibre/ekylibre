/* -*- Mode: Javascript; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2; coding: utf-8 -*- */
/*jslint browser: true */
/* List Javascript Inobtrusive Support for jQuery */

(function($) {

    // $(".list .pagination[data-list] a").ready(function(event) {
    //     var element = $(this);
    //     alert("0");
    //     element.attr("data-remote", "true");
    //     alert("1");
    //     element.attr("data-type", "html");
    //     alert("2");
    //     element.attr("data-list-update", element.closest(".pagination[data-list]").data("list"));
    //     alert("3");
    //     return true;
    // });


    // $("a[data-toggle-column]").on("click", function(event) {
    //     var element = $(this), columnId, column, className, search, visibility = '';
    //     columnId = element.data('toggle-column');
    //     column = $('#'+columnId);
    //     className = column.data("cells-class");
    //     if (className === null) { 
    //         className = columnId; 
    //     }
    //     search = '.'+className;
    //     if (column.hasClass("hidden")) {
    //         $(search).removeClass("hidden");
    //         column.removeClass("hidden");
    //         element.removeClass("unchecked");
    //         element.addClass("checked");
    //         visibility = 'shown';
    //     } else {
    //         $(search).addClass("hidden");
    //         column.addClass("hidden");
    //         element.removeClass("checked");
    //         element.addClass("unchecked");
    //         visibility = 'hidden';
    //     }
    //     var url = element.attr("href")
    //     if (url !== null) {
    //         $.ajax(url, {data: {visibility: visibility} });
    //     }
    //     return false;
    // });


    // $("select[data-per-page]").on("change", function(event) {
    //     var element = $(this), url = element.data('per-page');
    //     if (url !== null) {
    //         var update = element.data('update'), options = {data: {per_page: element.value}};
    //         if (update !== null) {
    //             options.success = function (data, status, xhr) {
    //                 $('#'+update).html(data);
    //             }
    //         }
    //         $.ajax(url, options);
    //     }
    //     return false;
    // });

    // $("a[data-remote-update]").on("click", function(event) {
    //     var element = $(this);
    //     var url = element.attr('href');
    //     var method = element.data('method') || 'get';
    //     var update = element.data('remote-update');
    //     $.ajax(url, {
    //         method: method,
    //         success: function (data, status, xhr) {
    //             $('#'+update).html(data); 
    //         }
    //     });
    //     return false;
    // });
    
    $.List = {};

    $.List.moveToPage() = function (list, fromWidget, page) {
        var per_page, total_lines, slider;
        list = $(list);
        slider = list.find("*[data-paginate-to]").first();
        // Get new page index
        if (page === null || page === undefined) {
            page = slider.slider("value");
        }

        // Change states
        list.find("*[data-list-page]").removeClass("disabled");
        if (page <= 1) {
            page = 1;
            list.find("*[data-list-page='first']").addClass("disabled");
            list.find("*[data-list-page='previous']").addClass("disabled");
        }
        if (page >= last) {
            page = last;
            list.find("*[data-list-page='next']").addClass("disabled");
            list.find("*[data-list-page='last']").addClass("disabled");
        }
        list.find("*[data-list-page-status]").each(function(index) {
            var element = $(this), text, from_line, to_line, total;
            from_line = (page-1) * per_page + 1;
            to_line = from_line + per_page - 1;
            if (to_line > total_lines) {
                to_line = total_lines;
            }
            total = Math.ceil(page / per_page);
            text = element.data('list-page-status').replace(/PAGE/g, '<em>'+page+'</em>')
                .replace(/TOTAL/g, '<em>'+total+'</em>')
                .replace(/FROM_LINE/g, '<em>'+from_line+'</em>')
                .replace(/TO_LINE/g, '<em>'+to_line+'</em>')
                .replace(/TOTAL_LINES/g, '<em>'+total_lines+'</em>')
            element.html(text);
        });
        if (fromWidget !== "slider") {
            
        }
        
        // AJAX
        
    }
    
    $.List.refreshPaginator = function (event, ui) {
        var element = $(this), url = element.data('url'), parameterName = (element.data('parameter-name') || 'page'), page = element.slider("value"), method = (element.data('method') || 'get'), dataType = element.data('type') || 'html', listId = '#'+element.closest("div.list[id]").attr("id"); //, page = element.slider("value");
        url = url.replace(new RegExp(parameterName.toUpperCase(), "g"), page);
        // Refresh TBODY
        if (element.data('loadingTableData') != 'true') {
            element.data('loadingTableData', 'true');
            $.ajax(url, {
                method: method,
                dataType: dataType,
                error: function(xhr, status, message) {
                    element.data('loadingTableData', 'false');
                },
                success: function (data, status, xhr) {
                    $(listId+' tbody').html(data);
                    element.data('loadingTableData', 'false');
                    if (page != element.slider("value")) {
                        $.List.refreshPaginator.call(element, null, null);
                    }
                }
            });
        }
        return true;
    }

    $.List.load = function (list) {
        var paginator;
        list = $(list);
        // Paginator
        list.find("*[data-paginate-to]").each(function(index) {
            var paginator, paginateFrom, paginateTo, paginateAt;
            paginator = $(this);
            paginateFrom = parseInt(paginator.data('paginate-from') || 1);
            paginateTo = parseInt(paginator.data('paginate-to'));
            paginateAt = parseInt(paginator.data('paginate-at'));
            paginator.slider({
			          range: "min",
			          value: paginateAt,
			          min: paginateFrom,
			          max: paginateTo,
                change: function (event, ui) {
                    $.List.goToPage(list, "slider");
                },
                slide: function (event, ui) {
                    $.List.goToPage(list, "slider");
                }
		        });
        });
        
        return true;
    }


    $(document).delegate('a[data-list]', 'click', function(event) {
        var element = $(this), url = element.attr('href'), method = element.data('method') || 'get', dataType = element.data('type') || 'html', update = '#'+element.data('list');
        $.ajax(url, {
            method: method,
            dataType: dataType,
            success: function (data, status, xhr) {
                $(update).html(data);
                $.List.load(update);
            }
        });
        return false;
    });

    $(document).ready(function() {
        $('*[data-paginate-to][data-list]').each(function(index) {
            $.List.load('#'+$(this).data("list"));
        });
    });


    // $('.pagination .paginator').ready(function(event) {
    //     alert('Load slider 2');
    // });

    // $("a[data-list-update]").on("ajax:success", function(event, data, status, xhr) {
    //     alert('Update list!');
    //     $($(this).data('list-update')).html(data);
    // });




    // $.behave(".list .pagination[data-list] a", "load", function(event) {
    //     $(this).attr("data-remote", "true");
    //     $(this).attr("data-list-update", $(this).closest(".pagination[data-list]").data("list"));
    // });

    // $.behave("a[data-toggle-column]", "click", function(event) {
    //     var element = $(this), columnId = element.data('toggle-column');
    //     var column = $('#'+columnId);
    //     var className = column.data("cells-class");
    //     if (className === null) { className = columnId; }
    //     var search = '.'+className;
    //     var visibility = '';
    //     if (column.hasClass("hidden")) {
    //         $(search).removeClass("hidden");
    //         column.removeClass("hidden");
    //         element.removeClass("unchecked");
    //         element.addClass("checked");
    //         visibility = 'shown';
    //     } else {
    //         $(search).addClass("hidden");
    //         column.addClass("hidden");
    //         element.removeClass("checked");
    //         element.addClass("unchecked");
    //         visibility = 'hidden';
    //     }
    //     var url = element.attr("href")
    //     if (url !== null) {
    //         $.ajax(url, {data: {visibility: visibility} });
    //     }
    //     return false;
    // });


    // $.behave("select[data-per-page]", "change", function(event) {
    //     var element = $(this), url = element.data('per-page');
    //     if (url !== null) {
    //         var update = element.data('update'), options = {data: {per_page: element.value}};
    //         if (update !== null) {
    //             options.success = function (data, status, xhr) {
    //                 $('#'+update).html(data);
    //             }
    //         }
    //         $.ajax(url, options);
    //     }
    //     return false;
    // });

    // $.behave("a[data-remote-update]", "click", function(event, element) {
    //     var url = element.attr('href');
    //     var method = element.data('method') || 'get';
    //     var update = element.data('remote-update');
    //     $.ajax(url, {
    //         method: method,
    //         success: function (data, status, xhr) {
    //             $('#'+update).html(data); 
    //         }
    //     });
    //     return false;
    // });

    // $.behave("a[data-list-update]", "ajax:success", function(event, data, status, xhr) {
    //     $($(this).data('list-update')).html(data);
    // });

})(jQuery);

