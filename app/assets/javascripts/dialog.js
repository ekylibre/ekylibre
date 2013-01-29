
(function ($) {

    $.Dialogram = {
	count: 0
    };

    $.Dialogram.open = function (url, settings) {
        var frame_id = "dialog-" + $.Dialogram.count, width = $(document).width();
        var defaultSettings = {
            header: "X-Return-Code",
            width: 0.6,
            height: 0.8
        };
        if (settings === null || settings === undefined) { settings = {}; }
        settings = $.extend({}, defaultSettings, settings);
        $.ajax(url, {
            data: {dialog: frame_id},
            success: function(data, status, request) {
                var frame = $(document.createElement('div')), width, height;
                frame.attr({id: frame_id, 'class': 'dialog ajax-dialog', style: 'display:none;'});
                $('body').append(frame);
                frame.html(data);
                frame.prop("dialogSettings", settings);
                if (settings.width === 0) {
                    width = 'auto';
                } else if (settings.width < 1) {
                    width = $(window).width() * settings.width;
                } else {
                    width = settings.width;
                }
                if (settings.height === 0) {
                    height = 'auto';
                } else if (settings.height < 1) {
                    height = $(window).height() * settings.height;
                } else {
                    height = settings.height;
                }
                frame.dialog({
                    autoOpen: false,
                    show: 'fade',
                    modal: true,
                    width: width,
                    height: height
                });
                $.Dialogram.initialize(frame);
                frame.dialog("open");
            },
            error: function(request, status, error) {
                alert("FAILURE (Error "+status+"): "+error);
                var frame = $("#" + frame_id);
                frame.dialog("close");
                frame.remove();
            }
        });
        $.Dialogram.count += 1;
    };

    $.Dialogram.initialize = function(frame) {
        var frame_id = frame.attr("id");
        var title = frame.prop("dialogSettings")["title"];
        if (title === null || title === undefined) {
            var h1 = $("#" + frame_id + " h1");
            if (h1[0] !== null && h1[0] !== undefined) {
                title = h1.text()
                h1.remove();
            }
        }
        frame.dialog("option", "title", title);

        $("#" + frame_id + " form").each(function (index, form) {
            $(form).attr('data-dialog', frame_id);
        });

    };

    $.submitAjaxForm = function () {
        var form = $(this);
        var frame_id = form.attr('data-dialog');
        var frame = $('#'+frame_id);
        var settings = frame.prop("dialogSettings");

        var field = $(document.createElement('input'));
        field.attr({ type: 'hidden', name: 'dialog', value: frame_id });
        form.append(field);

        $.ajax(form.attr('action'), {
            type: form.attr('method') || 'POST',
            data: form.serialize(),
            success: function(data, status, request) {
                var returnCode = request.getResponseHeader(settings["header"])
                var returns = settings["returns"], unknownReturnCode = true;
                for (var code in returns) {
                    if (returnCode == code && $.isFunction(returns[code])) {
                        returns[code].call(form, frame, data, status, request);
                        unknownReturnCode = false;
                        $.Dialogram.initialize(frame);
                        break;
                    }
                }
                if (unknownReturnCode) {
                    if ($.isFunction(settings["defaultReturn"])) {
                        settings["defaultReturn"].call(form, frame);
                    } else {
                        alert("FAILURE (Unknown return code for header " + settings["header"] + "): " + returnCode);
                    }
                }
            },
            error: function(request, status, error) {
                alert("FAILURE (Error "+status+"): "+error);
                var frame = $("#" + frame_id);
                frame.dialog("close");
                frame.remove();
                // if ($.isFunction(settings["error"])) { settings["error"].call(form, frame, request, status, error); }
            }
        });
        return false;
    };

    // Submits dialog forms
    $(document).behave("submit", ".ajax-dialog form[data-dialog]", $.submitAjaxForm);


})(jQuery);
