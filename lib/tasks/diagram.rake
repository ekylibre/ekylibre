module Diagrams
  class Graph
    OPTIONS = {
      damping: 'Damping',
      k: 'K',
      url: 'URL',
      background: '_background',
      arrow_head: 'arrowhead',
      arrow_size: 'arrowsize',
      arrow_tail: 'arrowtail',
      bounding_box: 'bb',
      background_color: 'bgcolor',
      cluster_rank: 'clusterrank',
      color_scheme: 'colorscheme',
      default_distance: 'defaultdist',
      dir_edge_constraints: 'diredgeconstraints',
      edge_url: 'edgeURL',
      edge_href: 'edgehref',
      edge_length: 'len',
      edge_target: 'edgetarget',
      edge_tooltip: 'edgetooltip',
      edge_separator: 'esep',
      fill_color: 'fillcolor',
      fixed_size: 'fixedsize',
      font_color: 'fontcolor',
      font_name: 'fontname',
      font_names: 'fontnames',
      font_path: 'fontpath',
      font_size: 'fontsize',
      force_labels: 'forcelabels',
      gradient_angle: 'gradientangle',
      head_url: 'headURL',
      head_clip: 'headclip',
      head_href: 'headhref',
      head_label: 'headlabel',
      head_port: 'headport',
      head_target: 'headtarget',
      head_tooltip: 'headtooltip',
      image_path: 'imagepath',
      image_scale: 'imagescale',
      input_scale: 'inputscale',
      label_url: 'labelURL',
      label_scheme: 'label_scheme',
      label_angle: 'labelangle',
      label_distance: 'labeldistance',
      label_float: 'labelfloat',
      label_font_color: 'labelfontcolor',
      label_font_name: 'labelfontname',
      label_font_size: 'labelfontsize',
      label_href: 'labelhref',
      label_just: 'labeljust',
      label_loc: 'labelloc',
      label_target: 'labeltarget',
      label_tooltip: 'labeltooltip',
      layer_list_separator: 'layerlistsep',
      layer_select: 'layerselect',
      layer_separator: 'layersep',
      levels_gap: 'levelsgap',
      logical_head: 'lhead',
      logical_tail: 'ltail',
      label_height: 'lheight',
      label_position: 'lp',
      label_width: 'lwidth',
      max_iteration: 'maxiter',
      mc_limit: 'mclimit',
      min_distance: 'mindist',
      min_length: 'minlen',
      node_separator: 'nodesep',
      no_justify: 'nojustify',
      no_translate: 'notranslate',
      ns_limit: 'nslimit',
      ns_limit1: 'nslimit1',
      output_order: 'outputorder',
      overlap: 'overlap',
      overlap_scaling: 'overlap_scaling',
      overlap_shrink: 'overlap_shrink',
      pack_mode: 'packmode',
      page_dir: 'pagedir',
      pen_color: 'pencolor',
      pen_width: 'penwidth',
      position: 'pos',
      quad_tree: 'quadtree',
      rank_dir: 'rankdir',
      rank_separator: 'ranksep',
      re_min_cross: 'remincross',
      repulsive_force: 'repulsiveforce',
      same_head: 'samehead',
      same_tail: 'sametail',
      sample_points: 'samplepoints',
      search_size: 'searchsize',
      separator: 'sep',
      shape: 'shape',
      shape_file: 'shapefile',
      show_boxes: 'showboxes',
      tail_url: 'tailURL',
      tail_lp: 'tail_lp',
      tail_clip: 'tailclip',
      tail_href: 'tailhref',
      tail_label: 'taillabel',
      tail_port: 'tailport',
      tail_target: 'tailtarget',
      tail_tooltip: 'tailtooltip',
      true_color: 'truecolor',
      dot_version: 'xdotversion',
      external_label: 'xlabel',
      external_label_position: 'xlp'
    }

    attr_accessor :processor, :name

    def initialize(*args)
      options = args.extract_options!
      @name = args.shift || options.delete(:name) || 'G'
      @type = args.shift || options.delete(:type) || 'graph'
      @node_options = options.delete(:node) || {}
      @edge_options = options.delete(:edge) || {}
      @processor = options.delete(:processor) || :dot
      @options = options
      options[:overlap] = false
      options[:font_name] ||= 'Open Sans'
      [:font_name].each do |attr|
        @node_options[attr] ||= @options[attr]
        @edge_options[attr] ||= @options[attr]
      end
      @edge_options[:font_color] ||= '#688ED8'
      [:head, :size, :tail].each do |key|
        if @edge_options[key]
          @edge_options["arrow_#{key}".to_sym] = @edge_options.delete(key)
        end
      end
      [:url, :href, :target, :tooltip, :length, :separator].each do |key|
        if @edge_options[key]
          @edge_options["edge_#{key}".to_sym] = @edge_options.delete(key)
        end
      end
      @content = ''
    end

    def node(name, options = {})
      @content << "  #{name}"
      @content << " #{options_for_dot(options)}" if options.any?
      @content << ";\n"
    end

    def arrow(from, to, options = {})
      [:head, :size, :tail].each do |key|
        options["arrow_#{key}".to_sym] = options.delete(key) if options[key]
      end
      options[:operator] = '->'
      edge(from, to, options)
    end

    def edge(from, to, options = {})
      [:url, :href, :target, :tooltip, :length, :separator].each do |key|
        options["edge_#{key}".to_sym] = options.delete(key) if options[key]
      end
      operator = options.delete(:operator) || '--'
      @content << "  #{from} #{operator} #{to}"
      @content << " #{options_for_dot(options)}" if options.any?
      @content << ";\n"
    end

    def subgraph(name, options = {}, &_block)
      @content << "  subgraph #{name} {\n"
      if options[:node]
        @content << "  node #{options_for_dot(options.delete(:node))};\n"
      end
      if options[:edge]
        @content << "  edge #{options_for_dot(options.delete(:edge))};\n"
      end
      @content << "  graph #{options_for_dot(options)};\n"
      yield
      @content << "  }\n"
    end

    def to_dot
      graph = "#{@type} #{@name.to_s.underscore} {\n"
      graph << "  graph #{options_for_dot(@options)};\n"
      graph << "  node  #{options_for_dot(@node_options)};\n"
      graph << "  edge  #{options_for_dot(@edge_options)};\n"
      graph << @content
      graph << '}'
    end

    def write(options = {})
      root = options[:dir] || Rails.root.join('doc', 'diagrams')
      dot_file = root.join("#{@name}.gv")
      FileUtils.mkdir_p(dot_file.dirname)
      File.write(dot_file, to_dot)
      formats = options[:formats] || %w(png)
      formats.each do |format|
        `#{@processor} -T#{format} #{dot_file} > #{root.join(@name.to_s + '.' + format.to_s)}`
      end
      FileUtils.rm_rf dot_file
    end

    protected

    def options_for_dot(hash)
      '[' + hash.map do |key, value|
        value = value.to_s if value.is_a?(Symbol)
        "#{OPTIONS[key] || key}=#{value.inspect}"
      end.join('; ') + ']'
    end
  end

  class << self
    # Build an inheritance graph with given root model
    def inheritance(model, options = {})
      YAML.load_file(Rails.root.join('db', 'models.yml')).map(&:classify).map(&:constantize)
      models = model.descendants
      options[:name] ||= "#{model.name.underscore}-inheritance"
      graph = Diagrams::Graph.new(options.delete(:name), :digraph, rank_dir: 'BT', edge: { color: '#999999' })
      graph.node model.name, href: "https://github.com/ekylibre/ekylibre/tree/master/app/models/#{model.name.underscore}.rb", font_color: '#002255', color: '#002255'
      models.sort { |a, b| a.name <=> b.name }.each do |model|
        graph.node model.name, href: "https://github.com/ekylibre/ekylibre/tree/master/app/models/#{model.name.underscore}.rb"
      end
      models.each do |model|
        graph.arrow(model.name, model.superclass.name, head: :empty)
      end
      graph
    end

    # Build a relational graph with given models
    def relational(*models)
      options = models.extract_options!
      options[:name] ||= "#{models.first.name.underscore}-relational"
      graph = Diagrams::Graph.new(options.delete(:name), :digraph, rank_dir: 'BT', node: { font_color: '#999999', color: '#999999' }, edge: { color: '#999999' })
      polymorphism = false
      models.sort { |a, b| a.name <=> b.name }.each do |model|
        graph.node(model.name, href: "https://github.com/ekylibre/ekylibre/tree/master/app/models/#{model.name.underscore}.rb", font_color: '#002255', color: '#002255')
        model.reflections.values.each do |reflection|
          next if reflection.macro != :belongs_to || model.name == reflection.class_name || %w(updater creator).include?(reflection.name.to_s) || (!reflection.polymorphic? && !models.include?(reflection.class_name.constantize))
          arrow_options = {}
          arrow_options[:label] = reflection.name if reflection.polymorphic? || reflection.name.to_s != reflection.class_name.underscore
          if reflection.polymorphic?
            polymorphism = true
            graph.arrow(model.name, 'AnyModel', arrow_options.merge(style: :dashed))
          else
            graph.arrow(model.name, reflection.class_name, arrow_options)
          end
        end
      end
      graph.node('AnyModel', style: :dashed) if polymorphism
      graph
    end
  end
end

namespace :diagrams do
  task all: :environment do
    models = YAML.load_file(Rails.root.join('db', 'models.yml')).map(&:classify).map(&:constantize).delete_if do |m|
      m.superclass != Ekylibre::Record::Base
    end
    graph = Diagrams.relational(*models, name: 'all')
    graph.write
  end

  task relational: :environment do
    {
      product: YAML.load_file(Rails.root.join('db', 'models.yml')).select do |m|
        m =~ /^product($|_)/ and not m =~ /^product_(group|nature)/ and m.pluralize == m.classify.constantize.table_name
      end.map(&:classify).map(&:constantize) + [Tracking],
      cash: [Cash, CashSession, CashTransfer, BankStatement, Deposit, IncomingPaymentMode, OutgoingPaymentMode, Loan, LoanRepayment],
      entity: [Entity, EntityLink, EntityAddress, Task, Event, EventParticipation, Observation, PostalZone, District],
      journal: [Journal, JournalEntry, JournalEntryItem, Account, FinancialYear, AccountBalance, Loan, LoanRepayment, BankStatement, Cash, FixedAsset, FixedAssetDepreciation], # , CashTransfer, CashSession]
      product_nature: [Product, ProductNature, ProductNatureVariant, ProductNatureCategory, ProductNatureVariantReading, ProductNatureCategoryTaxation],
      production: [Activity, ActivityDistribution, Campaign, Production, ProductionBudget, ProductionDistribution, ProductionSupport, Intervention, InterventionCast, Operation],
      sale: [Sale, SaleNature, SaleItem, OutgoingParcel, OutgoingParcelItem, Delivery, IncomingPayment, IncomingPaymentMode, Deposit],
      purchase: [Purchase, PurchaseNature, PurchaseItem, IncomingParcel, IncomingParcelItem, OutgoingPayment, OutgoingPaymentMode],
      delivery: [Delivery, OutgoingParcel, OutgoingParcelItem, IncomingParcel, IncomingParcelItem] # , Analysis, AnalysisItem
    }.each do |name, models|
      graph = Diagrams.relational(*models, name: "#{name}-relational")
      graph.write
    end
  end

  task inheritance: :environment do
    [Product, Affair].each do |model|
      graph = Diagrams.inheritance(model)
      graph.write
    end
  end
end

desc 'Write diagram files of models'
task diagrams: ['diagrams:relational', 'diagrams:inheritance']
