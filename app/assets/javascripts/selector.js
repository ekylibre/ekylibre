/* -*- mode: javascript; indent-tabs-mode: nil; -*- */
/*jslint browser: true, devel: true */
(function ($, undefined) {
    "use strict";

/*
    $.widget("ekylibre.selector", {
        _create: function () {
            
        }
    });
*/

    $.Selector = {
        init: function (element) {
            var selector = element, name, hidden, menu;
            name = selector.attr("name");
            selector.removeAttr("name");
            hidden = $("<input type='hidden' name='" + name + "'/>");
            if (selector.attr("required") === "true") {
                hidden.attr("required", "true");
            }
            selector.before(hidden);
            selector.prop("hiddenInput", hidden);
            selector.attr("autocomplete", "off");
            selector.after($("<a href='#" + selector.attr("id") + "' rel='dropdown'>&dArr;</a>"));
            selector.prop("lastSearch", selector.val());
            menu = $('<div class="items-menu"></div>');
            menu.hide();
            menu.prop("selectorOfMenu", selector);
            selector.after(menu);
            selector.prop("dropDownMenu", menu);
            return selector;
        },

        closeMenu: function (element) {
            var selector = element, menu, hidden, search;
            menu   = selector.prop("dropDownMenu");
            hidden = selector.prop("hiddenInput");
            if (selector.attr("required") === "true") {
                // Restore last value if possible
                if (hidden.val().length > 0) {
                    search = hidden.prop("itemLabel");
                }
            } else {
                // Empty values if empty
                if (selector.val().length <= 0) {
                    hidden.val("");
                    search = "";
                } else if (hidden.val().length > 0) {
                    search = hidden.prop("itemLabel");
                }
            }
            selector.prop("lastSearch", search);
            selector.val(search);
            if (menu.is(":visible")) {
                menu.hide();
            }
            return selector;
        },

        openMenu: function (element, search) {
            var selector = element, data = {}, menu;
            menu = selector.prop("dropDownMenu");
            if (search !== undefined) {
                data = {q: search};
            }
            $.ajax(selector.data("selector"), {
                dataType: "html",
                data: data,
                success: function (data, status, request) {
                    menu.html(data);
                    if (data.length > 0) {
                        menu.show();
                    } else {
                        menu.hide();
                    }
                },
                error: function (request, status, error) {
                    alert("AJAX failure on " + selector.data('selector') + " (Error " + status + "): " + error);
                }
            });
        },

        select: function (element, id, label) {
            var selector = element, menu, hidden;
            menu = selector.prop("dropDownMenu");
            hidden = selector.prop("hiddenInput");
            selector.prop("lastSearch", label);
            selector.val(label);
            hidden.prop("itemLabel", label);
            hidden.val(id);
            if (menu.is(":visible")) {
                menu.hide();
            }
            return selector;
        },

        set: function (element, id) {
            var selector = element;
            $.ajax(selector.data("selector"), {
                dataType: "json",
                data: {id: id},
                success: function (data, status, request) {
                    var item = $.parseJSON(request.responseText)[0];
                    $.Selector.select(selector, item.id, item.label);
                },
                error: function (request, status, error) {
                    alert("Cannot get details of item on " + selector.data('selector') + " (" + status + "): " + error);
                }
            });
            return selector;
        }

    };


    $(document).behave("load", "input[data-selector]", function (event) {
        $.Selector.init($(this));
        return false;
    });

    $(document).on("keyup", "input[data-selector]", function (event) {
        var selector = $(this), search, menu, code = (event.keyCode || event.which), selected;
        search = selector.val();
        menu = selector.prop("dropDownMenu");
        if (selector.prop("lastSearch") !== search) {
            if (search.length > 0) {
                $.Selector.openMenu(selector, search);
            } else {
                menu.hide();
            }
            selector.prop("lastSearch", search);
        } else {
            selected = menu.find("ul li.selected[data-item-label][data-item-id]").first();
            if (selected[0] === null || selected[0] === undefined) {
                selected = menu.find("ul li[data-item-label][data-item-id]").first();
                selected.addClass("selected");
            } else {
                if (code === 40) { // Down
                    if (!selected.is(":last-child")) {
                        selected.removeClass("selected");
                        selected.next().addClass("selected");
                    }
                } else if (code === 38) { // Up
                    if (!selected.is(":first-child")) {
                        selected.removeClass("selected");
                        selected.prev().addClass("selected");
                    }
                } else if (code === 27) { // Escape
                    menu.hide();
                }
            }
        }
        return false;
    });

    $(document).on("keypress", "input[data-selector]", function (event) {
        var selector = $(this), menu, code = (event.keyCode || event.which), selected;
        menu = selector.prop("dropDownMenu");
        if (code === 13 || code === 10) { // Enter
            selected = menu.find("ul li.selected[data-item-label][data-item-id]").first();
            if (selected[0] !== null && selected[0] !== undefined) {
                $.Selector.select(selector, selected.data("item-id"), selected.data("item-label"));
                return false;
            }
        }
        return true;
    });

    $(document).on("blur focusout", "input[data-selector]", function (event) {
        var selector = $(this);
        setTimeout(function () {
            $.Selector.closeMenu(selector);
        }, 300);
        return true;
    });

    $(document).behave("click", 'a[rel="dropdown"][href]', function (event) {
        var element = $(this), selector, menu;
        selector = $(element.attr("href"));
        menu = selector.prop("dropDownMenu");
        if (menu.is(":visible")) {
            menu.hide();
        } else {
            $.Selector.openMenu(selector);
        }
        return false;
    });

    $(document).on("hover", '.items-menu ul li[data-item-label][data-item-id]', function (event) {
        var element = $(this), list;
        list = element.closest("ul");
        list.find("li.selected[data-item-label][data-item-id]").removeClass("selected");
        element.addClass("selected");
        return false;
    });

    $(document).on("click", '.items-menu ul li[data-item-label][data-item-id]', function (event) {
        var selected = $(this), selector = selected.closest(".items-menu").prop("selectorOfMenu");
        $.Selector.select(selector, selected.data("item-id"), selected.data("item-label"));
        return false;
    });


})(jQuery);
