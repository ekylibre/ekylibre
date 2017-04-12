module Diagram
  module Model
    class << self
      # Build an inheritance graph with given root model
      def inheritance(model, options = {})
        YAML.load_file(Rails.root.join('db', 'models.yml')).map(&:classify).map(&:constantize)
        models = model.descendants
        options[:name] ||= "#{model.name.underscore}-inheritance"
        graph = Diagram::Graph.new(options.delete(:name), :digraph, rank_dir: 'BT', edge: { color: '#999999' })
        graph.node model.name, href: "https://github.com/ekylibre/ekylibre/tree/master/app/models/#{model.name.underscore}.rb", font_color: '#002255', color: '#002255'
        models.sort_by(&:name).each do |model|
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
        graph = Diagram::Graph.new(options.delete(:name), :digraph, rank_dir: 'BT', node: { font_color: '#999999', color: '#999999' }, edge: { color: '#999999' })
        polymorphism = false
        models.sort_by(&:name).each do |model|
          graph.node(model.name, href: "https://github.com/ekylibre/ekylibre/tree/master/app/models/#{model.name.underscore}.rb", font_color: '#002255', color: '#002255')
          model.reflections.values.each do |reflection|
            next if reflection.macro != :belongs_to || model.name == reflection.class_name || %w[updater creator].include?(reflection.name.to_s) || (!reflection.polymorphic? && !models.include?(reflection.class_name.constantize))
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

      def physical(*models)
        options = models.extract_options!
        options[:name] ||= "#{models.first.name.underscore}-relational"
        graph = Diagram::Graph.new(options.delete(:name), :digraph, rank_dir: 'LR', node: { font_color: '#999999', color: '#999999' }, edge: { color: '#999999' })
        polymorphism = false
        table_names = models.map(&:table_name).uniq.map(&:to_s)
        tables = YAML.load_file(Rails.root.join('db', 'tables.yml')).delete_if { |t, _| !table_names.include?(t) }
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
            next if references =~ /\A~/
            if tables.keys.include?(references.pluralize)
              graph.arrow(table_name + ':f' + index.to_s, references.pluralize + ':f999')
            end
          end
        end
        graph.record('any_models', style: :dashed) if polymorphism
        graph
      end
    end
  end
end
