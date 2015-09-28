(($) ->

  "use strict"

  $.widget "ui.attachmentController",
    options:
      fullWidget: false
      fullWidgetClass: 'expanded'

    _create: ->
      $.extend(true, @options, @element.data("attachment-controller"))

      widget = @
      @$el = $(@.element)
      @$root = @.element.closest('.attachments')

      @$el.fileupload
        dataType: 'json',
        dropZone: '.attachment-files'
        add: (e, data) =>
          console.log data.files
          $el = $('<div class="file">\
            <div class="file-body">\
            <div class="thumbnail"/>\
            <span class="file-name">'+data.files[0].name+'</span>\
            </div>\
            <div class="actions">\
            <a href="" data-attachment-destroy="true" disabled>\
            </a>\
            </div>\
            </div>')

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

          data.context.find('*[data-attachment-destroy]').addClass 'loading'
          true

        progressall: (e, data) ->
          $('.attachment-files-bitrate').text((data.bitrate / 1024).toFixed(2) + 'Kb/s')

        done: (e, data) ->
          $(data.context).find('.file-name').html("<a href='' data-href='#{data.result.attachment_path}' data-attachment-thumblink=true>#{data.result.attachment.name}</a>")
          $(data.context).find('.file-body').data('href', data.result.attachment_path)
          $(data.context).find('.file-body').data('attachment-thumblink', true)

          $(data.context).find('*[data-attachment-destroy]').data('href', data.result.attachment_path)

          $(data.context).find('.thumbnail').css("background-image", "url('#{data.result.thumb}')")

          data.context.find('*[data-attachment-destroy]').removeClass 'loading'
          data.context.find('*[data-attachment-destroy]').removeAttr 'disabled'

        fail: (e, data) ->
          $(data.context).find('.file-name').css 'color', 'red'
          data.context.find('*[data-attachment-destroy]').removeClass 'loading'
          data.context.find('*[data-attachment-destroy]').addClass 'failed'


        always: () ->
          $('.attachment-files-bitrate').text('')

      $(document).on 'click', '*[data-attachment-destroy]', (e) ->
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
            $el = $("<iframe src='#{data.url}'/>")
            $modal = $('*[data-attachment-thumblink-target]')
            $modal.find('.modal-title').html(data.name)
            $modal.find('.modal-body').html($el)
            $modal.modal('show')
          error: (data) ->
            console.log 'Unable to load file'

        false

      $(document).on 'click','*[data-attachments-expand]', (e) ->
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
      if @$root.find('.attachment-files').find('.file').length > 0
        $('.attachment-files-placeholder').hide()
      else
        $('.attachment-files-placeholder').show()


    toggleWidget: ->
      @options.fullWidget = !@options.fullWidget
      if @options.fullWidget
        $('.attachments').addClass @options.fullWidgetClass
      else
        $('.attachments').removeClass @options.fullWidgetClass

  $(document).ready ->
    $("*[data-attachment]").each ->
      $(@).attachmentController()

) jQuery
