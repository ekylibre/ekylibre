module Diagram
  module Schema
    class << self
      def physical(tables, options = {})
        options[:name] ||= 'physical'
        graph = Diagram::Graph.new(options.delete(:name), :digraph, rank_dir: 'LR', node: { font_color: '#999999', color: '#999999' }, edge: { color: '#999999' })
        polymorphism = false
        tables.each do |table_name, columns|
          columns = columns.delete_if { |k, _v| %w[creator_id created_at updater_id updated_at lock_version id].include?(k) }
          label = '<f999> ' + table_name
          columns.keys.each_with_index do |c, i|
            label << " | <f#{i}> #{c}"
          end
          graph.record(table_name, label: label, font_color: '#002255', color: '#002255')
          columns.each_with_index do |(_column, attributes), index|
            references = attributes['references']
            next unless references
            unless references =~ /\A~/
              graph.arrow(table_name + ':f' + index.to_s, references.pluralize + ':f999')
            end
          end
        end
        graph
      end
    end
  end
end
