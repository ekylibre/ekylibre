module Diagram
  module Nomenclature
    class << self
      def inheritance(nomenclature, options = {})
        options[:name] ||= "#{nomenclature.name.to_s.underscore}-inheritance"
        graph = Diagram::Graph.new(options.delete(:name), :digraph, rank_dir: 'RL', edge: { color: '#999999' })
        nomenclature.list.each do |item|
          graph.node item.name, font_color: '#002255', color: '#002255'
          graph.arrow(item.name, item.parent.name, head: :empty) if item.parent?
        end
        graph
      end

      def inheritance_all(nomenclature, options = {})
        options[:name] ||= "#{nomenclature.name.to_s.underscore}-inheritance"
        nomenclature.list.each do |item|
          if item.children.any?
            graph = Diagram::Graph.new("#{nomenclature.name.to_s.underscore}-#{item.name}", :digraph, rank_dir: 'RL', edge: { color: '#999999' })
            graph.node item.name, font_color: '#002266', color: '#002255'
            item.children(recursively: false).each do |i|
              graph.node i.name, font_color: '#002255', color: '#002255'
              graph.arrow(i.name, item.name, head: :empty)
            end
            if item.parent?
              graph.arrow(item.name, item.parent.name, head: :empty)
            end
            path = Rails.root.join('doc', 'diagrams', nomenclature.name.to_s).join(*item.self_and_parents.reverse.map(&:name).join('-'))
            graph.write(path: path.to_s)
          end
        end
      end
    end
  end
end
