module CobblesHelper

  class Cobble
    cattr_reader :current

    attr_reader :name, :block, :id, :title, :content
    def initialize(cobbler, name, options = {}, &block)
      @cobbler = cobbler
      @name = name
      @id = options[:id] || name.to_s.parameterize.dasherize
      @title = options[:title] || @name.tl
      @@current = self
      @content = @cobbler.template.capture(&block)
      @@current = nil
    end

    def others
      @cobbler.items.select{|c| c.id != @id }
    end
  end

  class Cobbler
    attr_reader :items, :template

    def initialize(template)
      @template = template
      @items = []
    end

    def cobble(name, options = {}, &block)
      if @items.detect{|i| i.name.to_s == name.to_s }
        raise "Already taken. You already use #{name.inspect}"
      end
      @items << Cobble.new(self, name, options, &block)
    end

    def any?
      @items.any?
    end

    def each(&block)
      @items.each(&block)
    end

  end

  # Cobbles are a simple layout with all cobble in one list.
  # List is sortable and cobbles are hideable/collapseable
  def cobbles(&block)
    cobbler = Cobbler.new(self)
    yield cobbler
    if cobbler.any?
      render "cobbles", cobbler: cobbler
    end
  end

  def cobble_toolbar(options = {}, &block)
    content_for("cobble_#{Cobble.current.id}_main_toolbar".to_sym, toolbar(options.merge(wrap: false), &block))
    return nil
  end

  def cobble_list(name, options = {}, &block)
    id = Cobble.current.id
    list(name, options.deep_merge(content_for: {
                                    settings:   "cobble_#{id}_meta_toolbar".to_sym,
                                    pagination: "cobble_#{id}_meta_toolbar".to_sym,
                                    actions:    "cobble_#{id}_main_toolbar".to_sym
                                  }), &block)
  end

  def cobble_toolbar_tag(cobble, name)
    tbid = "cobble_#{cobble.id}_#{name}_toolbar".to_sym
    if content_for?(tbid)
      content_tag(:div, content_for(tbid), class: "cobble-toolbar cobble-#{name.to_s.dasherize}-toolbar")
    end
  end


end
