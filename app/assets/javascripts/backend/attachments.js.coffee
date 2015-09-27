(($) ->

  "use strict"

  $.widget "ui.attachmentController",
    options:
      fullWidget: false
      fullWidgetClass: 'full-widget'

    _create: ->
      $.extend(true, @options, @element.data("attachment-controller"))

      widget = @
      @$el = $(@.element)
      @$root = @.element.closest('.attachments-panel')

      @$el.fileupload
        dataType: 'json',
        dropZone: '.attachment-files'
        add: (e, data) =>
          $el = $('<div class="file">\
            <div class="file-body">\
            <div class="thumbnail"/>\
            <span class="name">'+data.files[0].name+'</span>\
            </div>\
            <div class="actions">\
            <a href="" class="btn removebutton" data-attachment-file-destroy-button=true disabled>\
            </a>\
            </div>\
            </div>')

          if widget.options.fullWidget
            $el.addClass widget.options.fullWidgetClass
            $el.find('.file-body').addClass @options.fullWidgetClass
            $el.find('.actions').addClass @options.fullWidgetClass
            $el.find('.name').addClass @options.fullWidgetClass
            $el.find('.thumbnail').show()
          else
            $el.removeClass widget.options.fullWidgetClass
            $el.find('.file-body').removeClass @options.fullWidgetClass
            $el.find('.actions').removeClass @options.fullWidgetClass
            $el.find('.name').removeClass @options.fullWidgetClass
            $el.find('.thumbnail').hide()

          data.context = $el.appendTo(@$root.find('.attachment-files'))

          @refreshPlaceholder()

          # send request
          data.submit()
          true

        submit: (e, data) ->
          data.formData =
            'attachments[document_attributes][name]': data.files[0].name
            'attachments[document_attributes][key]': "#{new Date().getTime()}-#{data.files[0].name}"
            'attachments[document_attributes][uploaded]': true

          data.context.find('.removebutton').addClass 'loading'
          true

        progressall: (e, data) ->
          $('.attachment-files-bitrate').text((data.bitrate / 1024).toFixed(2) + 'Kb/s')

        done: (e, data) ->
          $(data.context).find('.name').html("<a href='' data-href='#{data.result.attachment_path}' data-attachment-thumblink=true>#{data.result.attachment.name}</a>")
          $(data.context).find('.file-body').data('href', data.result.attachment_path)
          $(data.context).find('.file-body').data('attachment-thumblink', true)

          $(data.context).find('*[data-attachment-file-destroy-button]').data('href', data.result.attachment_path)

          $(data.context).find('.thumbnail').css("background-image", "url('#{data.result.thumb}')")

          data.context.find('.removebutton').removeClass 'loading'
          data.context.find('.removebutton').removeAttr 'disabled'

        fail: (e, data) ->
          $(data.context).find('.name').css 'color', 'red'
          data.context.find('.removebutton').removeClass 'loading'
          data.context.find('.removebutton').addClass 'failed'


        always: () ->
          $('.attachment-files-bitrate').text('')

      $(document).on 'click', '*[data-attachment-file-destroy-button]', (e) ->
        e.preventDefault()

        $.ajax
          url: $(@).data('href')
          method: 'post'
          data: {"_method": "delete"}
          success: (data) =>
            $(e.currentTarget).closest('.file').remove()
            widget.refreshPlaceholder()

          error: (data) =>
            $(e.currentTarget).closest('.file').find('*[data-attachment-thumblink]').addClass 'failed'
            console.log 'Unable to delete file'
        false

      $(document).on 'click','*[data-attachment-thumblink]', (e) ->
        e.preventDefault()

        $.ajax
          url: $(@).data('href')
          method: 'GET'
          success: (data) ->
            $el = $("<iframe src='#{data.attachment}'/>")
            $modal = $('*[data-attachment-thumblink-target]')

            $modal.find('.modal-body').html($el)
            $modal.modal('show')
          error: (data) ->
            console.log 'unable to load file'

        false

      $(document).on 'click','*[data-attachment-expand]', (e) ->
        e.preventDefault()
        widget.toggleWidget()

      $(document).bind 'dragover', (e) ->
        dropZone = $('.attachment-files')
        timeout = window.dropZoneTimeout
        if !timeout
          dropZone.addClass 'in'
        else
          clearTimeout timeout
        found = false
        node = e.target
        loop
          if node == dropZone[0]
            found = true
            break
          node = node.parentNode
          unless node != null
            break
        if found
          dropZone.addClass 'hover'
        else
          dropZone.removeClass 'hover'
        window.dropZoneTimeout = setTimeout((->
          window.dropZoneTimeout = null
          dropZone.removeClass 'in hover'
          return
        ), 100)
        return

      @refreshPlaceholder()

    refreshPlaceholder: ->
      if @$root.find('.attachment-files').find('.file').length
        $('.attachment-files-placeholder').hide()
      else
        $('.attachment-files-placeholder').show()


    toggleWidget: ->
      @options.fullWidget = !@options.fullWidget

      $('.attachments-panel').toggleClass @options.fullWidgetClass
      $('.attachments-files').toggleClass @options.fullWidgetClass
      $('.file').toggleClass @options.fullWidgetClass
      $('.file-body').toggleClass @options.fullWidgetClass
      $('.actions').toggleClass @options.fullWidgetClass
      $('.name').toggleClass @options.fullWidgetClass
      $('.thumbnail').toggle()


  $(document).ready ->
    $("*[data-attachment]").each ->
      $(@).attachmentController()

) jQuery