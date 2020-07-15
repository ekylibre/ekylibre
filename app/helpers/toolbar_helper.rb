module ToolbarHelper
  # This class permit to register the composition of a toolbar
  class Toolbar
    def initialize(template)
      @template = template
    end

    def authorized?(*args)
      @template.authorized?(*args)
    end

    def group(options = {}, &_block)
      raise 'Nested group are forbidden' unless @group.nil?
      options[:class] = options[:class].to_s + ' btn-group'
      @template.content_tag(:div, options) do
        yield(self)
      end
    end

    def tool(name, url, options = {})
      @template.tool_to(name, url, options) if authorized?(url)
    end

    def mail_to(email_address, name = nil, html_options = {}, &block)
      if html_options[:class]
        html_options[:class] << ' btn btn-default icn btn-mail'
      else
        html_options[:class] = ' btn btn-default icn btn-mail'
      end
      @template.mail_to(email_address, name, html_options, &block)
    end

    def export(*natures, label: :print, **options)
      record = options[:resource] || @template.resource
      options[:key] ||= (record ? :number : Time.zone.now.strftime('%Y%m%d%H%M%S'))
      key = (options[:key].is_a?(Symbol) ? record.send(options[:key]) : options[:key]).to_s
      @template.dropdown_menu_button(label, class: options[:class]) do |menu|
        natures.each do |nature_name|
          nature = Nomen::DocumentNature.find(nature_name)
          modal_id = nature.name.to_s + '-exporting'
          if Document.of(nature.name, key).any?
            @template.content_for :popover, @template.render('backend/shared/export', nature: nature, key: key, modal_id: modal_id, document_label: options[:document_label])
            menu.item options[:item_label] || nature.human_name, '#' + modal_id, data: { toggle: 'modal' }
          else
            DocumentTemplate.of_nature(nature.name).each do |template|
              menu.item(options[:item_label] || template.name, @template.params.merge(format: :pdf, template: template.id, key: key))
            end
          end
        end
        yield menu if block_given?
      end
    end

    # Propose all listings available for given models. Model is one of current
    # controller. Option +:model+ permit to change it.
    def extract(options = {})
      return nil unless @template.current_user.can?(:execute, :listings)
      model = options[:model] || @template.controller_name.to_s.singularize
      unless Listing.root_model.values.include?(model.to_s)
        raise "Invalid model for listing: #{model}"
      end
      listings = Listing.where(root_model: model).order(:name)
      @template.dropdown_menu_button(:extract, force_menu: true) do |menu|
        listings.each do |listing|
          menu.item(listing.name, controller: '/backend/listings', action: :extract, id: listing.id, format: :csv)
        end
        if options[:new].is_a?(TrueClass) && @template.current_user.can?(:write, :listings)
          menu.separator if listings.any?
          menu.item(:new_listing.tl, controller: '/backend/listings', action: :new, root_model: model)
        end
      end
    end

    def menu(name, options = {}, &block)
      @template.dropdown_menu_button(name, options, &block)
    end

    def destroy(resource = nil, label: :destroy.ta, redirect: nil, **options)
      options = {
        method: :delete,
        **options
      }
      resource ||= @template.resource

      if resource
        destroy_resource(resource, label: label, redirect: redirect, **options)
      else
        tool(label, { action: :destroy, redirect: redirect }, options)
      end
    end

    def edit(*args)
      options = args.extract_options!
      controller_options = options[:controller] ? { controller: options[:controller] } : {}
      if @template.resource
        if @template.resource.updateable?
          tool(options[:label] || :edit.ta, **controller_options, action: :edit, id: @template.resource.id, redirect: options[:redirect])
        end
      else
        tool(options[:label] || :edit.ta, { **controller_options, action: :edit, redirect: options[:redirect] }, options.except(:redirect, :label))
      end
    end

    def action(name, *args)
      options = args.extract_options!
      record = args.shift
      url = {}
      url.update(options.delete(:params)) if options[:params].is_a? Hash
      url[:controller] ||= @template.controller_path
      url[:action] ||= name
      url[:id] = record.id if record && record.class < ActiveRecord::Base
      url[:format] = options.delete(:format) if options.key?(:format)
      action_label = options[:label] || I18n.t(name, scope: 'rest.actions')
      url[:nature] = options[:nature] if options[:nature]
      if options[:variants]
        variants = options.delete(:variants)
        # variants ||= { action_label => url } if authorized?(url)
        # variants ||= {}
        menu(action_label, options) do |menu|
          variants.each do |name, url_options, link_options|
            variant_url = url.merge(url_options)
            if authorized?(variant_url)
              menu.item(name, variant_url, options.slice(:method, 'data-confirm').merge(link_options || {}))
            end
          end
        end
      else
        tool(action_label, url, options)
      end
    end

    def method_missing(method_name, *args)
      raise ArgumentError, 'Block can not be accepted' if block_given?
      options = args.extract_options!
      name = method_name.to_s.gsub(/\_+$/, '').to_sym
      record = args.shift
      action(name, record, options)
    end

    private

      def destroy_resource(resource, label:, redirect:, **options)
        options = {
          show_disabled: false,
          disabled_tooltip_content: false,
          data: { confirm: :are_you_sure_you_want_to_delete.tl },
          **options
        }
        show_disabled = options.fetch(:show_disabled)
        return ''.html_safe if !show_disabled && !resource.destroyable?

        unless resource.destroyable?
          options = {
            **options,
            disabled: true,
            style: 'pointer-events: auto'
          }

          if (tooltip_content = options.fetch(:disabled_tooltip_content))
            options = { **options, data: { toggle: :tooltip, placement: :top }, title: tooltip_content }
          end
        end

        tool(label, { action: :destroy, id: resource.id, redirect: redirect }, options)
      end
  end

  # Build a tool bar composed of tool groups composed of tool
  def toolbar(options = {}, &block)
    toolbar = Toolbar.new(self)

    html = ''
    html << (capture(toolbar, &block) || '') if block_given?

    if !options[:extract].is_a?(FalseClass) && action_name == 'index'
      model = controller_name.to_s.singularize
      if Listing.root_model.values.include?(model.to_s)
        html << (capture(toolbar) do |t|
          t.extract(options[:extract].is_a?(Hash) ? options[:extract] : {})
        end || '')
      end
    end

    if options[:name] == :main
      html << (Ekylibre::View::Addon.render(:main_toolbar, self, t: toolbar) || '')
    end

    safe_html = html.html_safe
    unless options[:wrap].is_a?(FalseClass)
      safe_html = content_tag(:div, safe_html, class: ['toolbar', 'toolbar-wrapper', options.fetch(:class, [])].flatten)
    end

    safe_html
  end
end
