/* -*- mode: javascript; indent-tabs-mode: nil; -*- */
/*jslint browser: true, devel: true */
(function ($) {
    "use strict";

    $.EkylibreSelector = {
        init: function (element) {
            var selector = $(element), name, hidden, menu, button;
            if (selector.prop("hiddenInput") === undefined) {
                name = selector.attr("name");
                selector.removeAttr("name");
                hidden = $("<input type='hidden' name='" + name + "'/>");
                if (selector.attr("required") === "true") {
                    hidden.attr("required", "true");
                }
                selector.closest("form").prepend(hidden);
                selector.prop("hiddenInput", hidden);
            }
            selector.attr("autocomplete", "off");
            if (selector.prop("dropDownButton") === undefined) {
                button = $("<a href='#" + selector.attr("id") + "' rel='dropdown' class='selector-dropdown'><i></i></a>");
                selector.after(button);
                selector.prop("lastSearch", selector.val());
                selector.prop("dropDownButton", button);
            }
            if (selector.prop("dropDownMenu") === undefined) {
                menu = $('<div class="items-menu"></div>');
                menu.hide();
                menu.prop("selectorOfMenu", selector);
                selector.after(menu);
                selector.prop("dropDownMenu", menu);
            }
            $.EkylibreSelector.set(selector, selector.val());
            return selector;
        },

        initAll: function () {
            $("input[data-selector]").each(function (index) {
                $.EkylibreSelector.init($(this));
            });
            return true;
        },

        getSourceURL: function (element) {
            var selector = element;
            // Adds data-change-source management
            return selector.data("selector");
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
            return $.ajax($.EkylibreSelector.getSourceURL(selector), {
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
            var selector = element, menu, hidden, len;
            menu = selector.prop("dropDownMenu");
            hidden = selector.prop("hiddenInput");
            selector.prop("lastSearch", label);
            selector.val(label);
            len = 10 * Math.round(Math.round(1.5 * label.length) / 10);
            selector.attr("size", (len < 20 ? 20 : len > 80 ? 80 : len));
            hidden.prop("itemLabel", label);
            hidden.val(id);
            if (menu.is(":visible")) {
                menu.hide();
            }
            return selector;
        },

        set: function (element, id) {
            var selector = element;
            if (id !== undefined && id !== "") {
                $.ajax($.EkylibreSelector.getSourceURL(selector), {
                    dataType: "json",
                    data: {id: id},
                    success: function (data, status, request) {
                        var list_item = $.parseJSON(request.responseText)[0];
                        if (list_item === undefined || list_item === null) {
                            console.log("JSON cannot be parsed. Get: " + request.responseText);
                        } else {
                            $.EkylibreSelector.select(selector, list_item.id, list_item.label);
                        }
                    },
                    error: function (request, status, error) {
                        alert("Cannot get details of item on " + selector.data('selector') + " (" + status + "): " + error);
                    }
                });
            }
            return selector;
        },

        choose: function (element, selected) {
            var selector = element, parameters, menu;
            if (selected === undefined) {
                menu = selector.prop('dropDownMenu');
                selected = menu.find("ul li.selected.item").first();
            }
            if (selected[0] !== null && selected[0] !== undefined) {
                if (selected.is("[data-item-label][data-item-id]")) {
                    $.EkylibreSelector.select(selector, selected.data("item-id"), selected.data("item-label"));
                } else if (selected.is("[data-new-item]")) {
                    parameters = {};
                    if (selected.data('new-item').length > 0) {
                        parameters = {name: selected.data('new-item')};
                    }
                    $.ajaxDialog(selector.data('selector-new-item'), {
                        data: parameters,
                        returns: {
                            success: function (frame, data, status, request) {
                                var record_id = request.getResponseHeader("X-Saved-Record-Id");
                                $.EkylibreSelector.set(selector, record_id);
                                frame.dialog("close");
                            },
                            invalid: function (frame, data, textStatus, request) {
                                frame.html(request.responseText);
                            }
                        }
                    });
                } else {
                    alert("Don't known how to manage this option");
                    console.log("Don't known how to manage this option");
                }
            } else {
                console.log("No selected item to choose...");
            }
            return selector;
        }

    };

    $(document).on("keypress", "input[data-selector]", function (event) {
        var selector = $(this), menu, code = (event.keyCode || event.which);
        menu = selector.prop("dropDownMenu");
        if (code === 13 || code === 10) { // Enter
            if (menu.is(":visible")) {
                $.EkylibreSelector.choose(selector);
                return false;
            }
        } else if (code === 40) { // Down
            if (menu.is(":hidden")) {
                $.EkylibreSelector.openMenu(selector, selector.val());
                return false;
            }
        }
        return true;
    });

    $(document).on("keyup", "input[data-selector]", function (event) {
        var selector = $(this), search, menu, code = (event.keyCode || event.which), selected;
        search = selector.val();
        menu = selector.prop("dropDownMenu");
        if (selector.prop("lastSearch") !== search) {
            if (search.length > 0) {
                $.EkylibreSelector.openMenu(selector, search);
            } else {
                menu.hide();
            }
            selector.prop("lastSearch", search);
        } else if (menu.is(":visible")) {
            selected = menu.find("ul li.selected.item").first();
            if (code === 27) { // Escape
                menu.hide();
            } else if (selected[0] === null || selected[0] === undefined) {
                selected = menu.find("ul li.item").first();
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
                }
            }
        }
        return true;
    });

    $(document).on("blur focusout", "input[data-selector]", function (event) {
        var selector = $(this);
        setTimeout(function () {
            $.EkylibreSelector.closeMenu(selector);
        }, 300);
        return true;
    });


    $(document).on("click", 'a.selector-dropdown[rel="dropdown"][href]', function (event) {
        var element = $(this), selector, menu;
        selector = $(element.attr("href"));
        menu = selector.prop("dropDownMenu");
        if (menu.is(":visible")) {
            menu.hide();
        } else {
            $.EkylibreSelector.openMenu(selector);
        }
        return false;
    });

    $(document).on("blur focusout", 'a.selector-dropdown[rel="dropdown"][href]', function (event) {
        var element = $(this), selector, menu;
        selector = $(element.attr("href"));
        setTimeout(function () {
            $.EkylibreSelector.closeMenu(selector);
        }, 300);
        return true;
    });


    $(document).on("mouseenter hover", '.items-menu ul li.item', function (event) {
        var element = $(this), list;
        list = element.closest("ul");
        list.find("li.item.selected").removeClass("selected");
        element.addClass("selected");
        return false;
    });

    $(document).on("click", '.items-menu ul li.item', function (event) {
        var selected = $(this), selector = selected.closest(".items-menu").prop("selectorOfMenu");
        $.EkylibreSelector.choose(selector, selected);
        return false;
    });


    // First initialization
    // $(document).ready($.EkylibreSelector.initAll);
    // $(document).ajaxComplete($.EkylibreSelector.initAll);

    // Other initializations
    $(document).behave("load", "input[data-selector]", function (event) {
        $.EkylibreSelector.init($(this));
        return true;
    });

    // don't remove for instancve because of Capybara navigation and other
    // see @burisu for authorization

     $(document).ready(function() {
       $("input[data-selector]").each(function (){
       	$.EkylibreSelector.init($(this));
       });
     })

})(jQuery);
