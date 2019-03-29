module CobblesHelper
  class Cobble
    cattr_reader :current

    attr_reader :name, :block, :id, :title, :content
    attr_accessor :position

    def initialize(cobbler, name, options = {}, &block)
      @cobbler = cobbler
      @name = name
      @id = options[:id] || name.to_s.parameterize.dasherize
      @title = options[:title] || @name.tl(default: ["attributes.#{@name}".to_sym, @name.to_s.humanize])
      @@current = self
      @content = @cobbler.template.capture(&block)
      @position = options[:position] || 1000
      @@current = nil
    end

    def others
      @cobbler.items.reject { |c| c.id == @id }
    end
  end

  class Cobbler
    attr_reader :items, :template, :name

    def initialize(template, name, options = {})
      @template = template
      @name = name
      @items = []
      @order = options[:order] || []
    end

    def cobble(name, options = {}, &block)
      if @items.detect { |i| i.name.to_s == name.to_s }
        raise "Already taken. You already use #{name.inspect}"
      end
      raise "Need a block for #{name} in cobbler #{@name}" unless block_given?
      @items << Cobble.new(self, name, options, &block)
    end

    def any?
      @items.any?
    end

    def sort!
      @order.each_with_index do |name, index|
        @items.select do |cobble|
          cobble.id.to_s == name.to_s
        end.each do |cobble|
          cobble.position = index + 1
        end
      end
      @items.sort! do |a, b|
        a.position <=> b.position
      end
    end

    def each(&block)
      @items.each(&block)
    end
  end

  # Cobbles are a simple layout with all cobble in one list.
  # List is sortable and cobbles are hideable/collapseable
  def cobbles(options = {}, &_block)
    name = options[:name] || "#{controller_name}-#{action_name}".to_sym
    config = YAML.safe_load(current_user.preference("cobbler.#{name}", {}.to_yaml).value).deep_symbolize_keys
    cobbler = Cobbler.new(self, name, order: config[:order])
    yield cobbler

    # Nothing expected at output
    Ekylibre::View::Addon.render(:cobbler, self, c: cobbler)

    if cobbler.any?
      cobbler.sort!
      render 'cobbles', cobbler: cobbler
    end
  end

  def cobble_toolbar(options = {}, &block)
    content_for("cobble_#{Cobble.current.id}_main_toolbar".to_sym, toolbar(options.merge(wrap: false), &block))
    nil
  end

  def cobble_meta_toolbar(&block)
    id = Cobble.current.id
    content_for("cobble_#{id}_meta_toolbar".to_sym, &block)
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
