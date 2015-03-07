
(function ($) {

  $.Dialoframe = {
    count: 0,

    defaultSettings: {
      header: "X-Return-Code",
      width: 0.6,
      height: 0.8
    },

    open: function (url, settings) {
      var frame_id = "dialog-" + $.Dialoframe.count, width = $(document).width(), frame = $(document.createElement('iframe')), width, height;
      if (settings === null || settings === undefined) { settings = {}; }
      settings = $.extend({}, $.Dialoframe.defaultSettings, settings);
      /* Open the iframe */
      width = $(window).width() * 0.6;
      height = $(window).height() * 0.8;
      frame.attr({id: frame_id, 'class': 'dialog ajax-dialog', style: 'display:none;', src: url + "?" + $.param({dialog: frame_id})});
      frame.css({width: width, height: height});
      $('body').append(frame);
      frame.prop("dialogSettings", settings);
      frame.dialog({
        autoOpen: false,
        show: 'fade',
        modal: true,
        width: width,
        height: height
      });
      frame.dialog("open");
      $.Dialoframe.count += 1;
    }
  }

  $.Dialoframe.initialize = function(frame) {
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
            $.Dialoframe.initialize(frame);
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
  /*
    $(document).behave("submit", ".true-dialog .ajax-dialog form[data-dialog]", function () {
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
    $.Dialoframe.initialize(frame);
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
    });
  */

  $(document).behave("click", "a[href][data-new-itemz]", function () {
    var element = $(this), url;
    url = element.attr("href");
    $.Dialoframe.open(url);
    return false;
  });


})(jQuery);
