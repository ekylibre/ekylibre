(($) ->

  # // Initializes date fields
  # $(document).behave("focusin click keyup change", 'input[data-date]', function (event) {
  #   var element = $(this), locale, options = {}, name, hidden;
  #   if (element.prop("datepickerLoaded") !== "Yes!") {
  #     locale = element.data("date-locale");
  #     if ($.datepicker.regional[locale] === null || $.datepicker.regional[locale] === undefined) {
  #       locale = "en";
  #     }
  #     $.datepicker.setDefaults( $.datepicker.regional[locale] );
  #     name = element.attr("name");
  #     element.removeAttr("name");
  #     hidden = $("<input type='hidden' name='" + name + "'/>");
  #     hidden.val(element.data("date-iso"));
  #     element.before(hidden);

  #     options['dateFormat']  = element.data("date");
  #     options['altField']    = hidden;
  #     options['altFormat']   = 'yy-mm-dd';
  #     options['defaultDate'] = element.val();

  #     // Check for dependents
  #     if (hidden.data('dependents') !== undefined && hidden.data('dependents') !== null) {
  #       if (hidden.data('observe') === undefined || hidden.data('observe') === null) {
  #         hidden.attr('data-observe', '1000');
  #       }
  #     }
  #     element.datepicker(options);
  #     element.prop("datepickerLoaded", "Yes!");
  #   }
  # });
  if not Modernizr.touch or not Modernizr.inputtypes.date

    # Initializes date fields
    $(document).on "focusin click keyup change", "input[type=\"date\"]", (event) ->
      element = $(this)
      locale = undefined
      options = {}
      name = undefined
      hidden = undefined
      if element.attr("autocomplete") isnt "off"
        locale = element.attr("lang")

        # if ($.datepicker.regional[locale] === null || $.datepicker.regional[locale] === undefined) {
        # 	locale = "en";
        # }
        # $.datepicker.setDefaults( $.datepicker.regional[locale] );
        # name = element.attr("name");
        # element.removeAttr("name");
        # hidden = $("<input type='hidden' name='" + name + "'/>");
        # hidden.val(element.val());
        # element.before(hidden);

        # options['dateFormat']  = element.data("format");
        # options['altField']    = hidden;
        # options['altFormat']   = 'yy-mm-dd';

        # // Check for dependents
        # if (hidden.data('dependents') !== undefined && hidden.data('dependents') !== null) {
        # 	if (hidden.data('observe') === undefined || hidden.data('observe') === null) {
        # 		hidden.attr('data-observe', '1000');
        # 	}
        # }
        $.extend options, $.datepicker.regional[locale],
          dateFormat: "yy-mm-dd"

        element.datepicker options
        element.attr "autocomplete", "off"
      return


    # Initializes datetime fields
    $(document).on "focusin click keyup change", "input[type=\"datetime\"]", (event) ->
      element = $(this)
      locale = undefined
      options = {}
      name = undefined
      hidden = undefined
      if element.attr("autocomplete") isnt "off"
        #TODO: change this
        date = new Date(element.val())
        dateString = date.getFullYear() + "-" + (date.getMonth()+1) + "-" + date.getDate() + " " +date.getHours() + ":" + date.getMinutes()
        element.val(dateString)

        locale = element.attr("lang")
        element.datetimepicker # options);
          format: "yyyy-mm-dd hh:ii"
          language: locale
          autoclose: true
          minuteStep: 5
          todayBtn: true

        element.attr "autocomplete", "off"
      return


  # $.initializeDateSelectors = function() {
  #   // $('input[type="date"], input[type="datetime"]').trigger('change');
  #   $('input[type="date"]').trigger('change');
  # };
  # $(document).ready($.initializeDateSelectors);
  # $(document).on("page:load cocoon:after-insert", $.initializeDateSelectors);


  return
) jQuery
