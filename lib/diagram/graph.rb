module Diagram
  # Tool class to write dot file
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
    }.freeze

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
      %i[head size tail].each do |key|
        if @edge_options[key]
          @edge_options["arrow_#{key}".to_sym] = @edge_options.delete(key)
        end
      end
      %i[url href target tooltip length separator].each do |key|
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

    def record(name, options = {})
      node(name, options.merge(shape: 'record'))
    end

    def arrow(from, to, options = {})
      %i[head size tail].each do |key|
        options["arrow_#{key}".to_sym] = options.delete(key) if options[key]
      end
      options[:operator] = '->'
      edge(from, to, options)
    end

    def edge(from, to, options = {})
      %i[url href target tooltip length separator].each do |key|
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
      path = options[:path] || Rails.root.join('doc', 'diagrams', @name.to_s).to_s
      dot_file = "#{path}.gv"
      FileUtils.mkdir_p(File.dirname(dot_file))
      File.write(dot_file, to_dot)
      formats = options[:formats] || %w[png]
      formats.each do |format|
        `#{@processor} -T#{format} #{dot_file} > #{path + '.' + format.to_s}`
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
end
