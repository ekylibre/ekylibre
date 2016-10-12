module Unrollable
  extend ActiveSupport::Concern

  module ClassMethods
    # Create unroll action for all scopes in the model corresponding to the controller
    # including the default scope
    def unroll(*columns)
      available_options = [:model, :max, :order, :partial, :fill_in, :scope]
      options = if columns.last.is_a?(Hash) && (columns.last.keys - available_options).empty?
                  columns.last.slice!(available_options)
                else
                  {}
                end
      model = (options.delete(:model) || controller_name).to_s.classify.constantize
      scope_name = options.delete(:scope) || 'unscoped'
      max = options[:max] || 80
      available_methods = model.columns_definition.keys.map(&:to_sym)

      columns = compactify(columns)

      # Sets default parameters
      if columns.blank?
        columns = [:title, :label, :full_name, :name, :code, :number, :reference_number].select do |x|
          available_methods.include?(x)
        end
      end

      if columns.blank?
        raise "Cannot unroll #{model.name} records. No column available (#{columns.inspect})."
      end

      # Normalize parameters
      filters  = filterify(columns, model)
      includes = includify(columns)

      unless order = options[:order]
        order = filters.map { |f| f[:search] }.compact
        order ||= :id
      end
      roots = filters.select { |f| f[:root] }
      fill_in = (options.key?(:fill_in) ? options[:fill_in] : roots.any? ? roots.first[:column_name] : nil)
      fill_in = fill_in.to_sym unless fill_in.nil?

      if !fill_in.nil? && !filters.detect { |c| c[:name] == fill_in }
        raise StandardError, "Label (#{filters.inspect}) of unroll must include the primary column: #{fill_in.inspect}"
      end

      searchable_filters = filters.select { |c| c[:pattern] && c[:column_type] != :boolean }
      unless searchable_filters.any?
        raise "No searchable filters for #{controller_path}#unroll.\nFilters: #{filters.inspect}\nColumns: #{columns.inspect}"
      end

      item_label = "'unrolls.#{controller_path}'.t(" + filters.map do |f|
        "#{f[:name]}: #{f[:expression]}, "
      end.join + "default: '" + filters.map { |f| "%{#{f[:name]}}" }.join(', ') + "')"

      haml = ''
      haml << "- if items.any?\n"
      haml << "  %ul.items-list\n"
      haml << "    - items.limit(items.count > #{(max * 1.5).round} ? #{max} : #{max * 2}).each do |item|\n"
      haml << "      - item_label = #{item_label}\n"
      haml << '      - attributes = {'
      filters.each do |f|
        haml << "#{f[:name]}: #{f[:expression]}, "
      end
      haml << "}\n"
      haml << "      %li.item{data: {item: {label: item_label, id: item.id}.merge(attributes.to_h)}}\n"
      haml << '        = ' + (options[:partial] ? "render '#{partial}', item: item" : 'highlight(item_label, keys)') + "\n"
      haml << "    - if params[:insert].to_i > 0\n"
      haml << "      %li.item.special{data: {new_item: ''}}= 'labels.add_#{model.name.underscore}'.t(default: [:'labels.add_new_record'])\n"
      haml << "  - if items.count > #{(max * 1.5).round}\n"
      haml << "    %span.items-status.items-status-too-many-records\n"
      haml << "      = 'labels.x_items_remain'.t(count: (items.count - #{max}))\n"
      haml << "- elsif params[:insert].to_i > 0\n"
      haml << "  %ul.items-list\n"
      unless fill_in.nil?
        haml << "    - unless search.blank?\n"
        haml << "      %li.item.special{data: {new_item: search, new_item_parameter: '#{fill_in}'}}= :add_x.th(x: search).html_safe\n"
      end
      haml << "    %li.item.special{data: {new_item: ''}}= 'labels.add_#{model.name.underscore}'.t(default: [:'labels.add_new_record'])\n"
      haml << "- else\n"
      haml << "  %span.items-status.items-status-empty\n"
      haml << "    = :no_results.tl\n"

      # Write haml in cache
      path = controller_path.split('/')
      path[-1] << '.html.haml'
      view = Rails.root.join('tmp', 'cache', 'unroll', *path)
      FileUtils.mkdir_p(view.dirname)
      File.open(view, 'wb') do |f|
        f.write(haml)
      end

      code = "def unroll\n"
      code << "  conditions = []\n"

      code << "  klass = controller_name.classify.constantize\n"
      code << "  items = klass.#{scope_name}"
      unless includes.empty?
        code << ".includes(#{includes.inspect})"
        code << ".references(#{includes.inspect})"
      end
      code << ".reorder(#{order.inspect})\n"
      code << "  scopes = params[:scope]\n"
      code << "  if scopes\n"
      code << "    scopes = { scopes.to_sym => true } if scopes.is_a?(String) || scopes.is_a?(Symbol)\n"
      code << "    scopes.symbolize_keys.each do |scope, parameters|\n"
      code << "      if klass.simple_scopes.map(&:name).include?(scope)\n"
      code << "        if (parameters.is_a?(TrueClass) or parameters == 'true')\n"
      code << "          items = items.send(scope)\n"
      code << "        elsif (parameters.is_a?(Array))\n"
      code << "          parameters.map! { |p| p.is_a?(Hash) ? p.symbolize_keys : p }\n"
      code << "          items = items.send(scope, *parameters)\n"
      code << "        else\n"
      code << "          logger.error(\"Scope \#{scope.inspect} is unknown for \#{klass.name}. \#{klass.scopes.map(&:name).inspect} are expected.\")\n"
      code << "          head :bad_request\n"
      code << "          return false\n"
      code << "        end\n"
      code << "      elsif parameters.is_a?(String) && klass.complex_scopes.map(&:name).include?(scope)\n"
      code << "          items = items.send(scope, *(parameters.strip.split(/\s*\,\s*/)))\n"
      code << "      else\n"
      code << "        logger.error(\"Scope \#{scope.inspect} is unknown for \#{klass.name}. \#{klass.scopes.map(&:name).inspect} are expected.\")\n"
      code << "        head :bad_request\n"
      code << "        return false\n"
      code << "      end\n"
      code << "    end\n"
      code << "  end\n"

      code << "  if excluded = params[:exclude]\n"
      code << "    items = items.where.not(id: params[:exclude])\n"
      code << "  end\n"

      code << "  keys = params[:q].to_s.strip.mb_chars.downcase.normalize.split(/[\\s\\,]+/)\n"
      code << "  if params[:id]\n"
      code << "    if params[:keep].to_s == 'true'\n"
      code << "      items = klass.where(id: params[:id])\n"
      code << "    else\n"
      code << "      items = items.where(id: params[:id])\n"
      code << "    end\n"
      code << "  elsif keys.any?\n"
      code << "    conditions = ['(']\n"
      code << "    keys.each_with_index do |key, index|\n"
      code << "      conditions[0] << ') AND (' if index > 0\n"
      code << '      conditions[0] << ' + searchable_filters.collect do |column|
        "LOWER(CAST(#{column[:search]} AS VARCHAR)) ILIKE E?"
      end.join(' OR ').inspect + "\n"
      code << '      conditions += [' + searchable_filters.collect do |column|
        column[:pattern].inspect.gsub('X', '" + key + "')
                        .gsub(/(^\"\"\s*\+\s*|\s*\+\s*\"\"\s*\+\s*|\s*\+\s*\"\"$)/, '')
      end.join(', ') + "]\n"
      code << "    end\n"
      code << "    conditions[0] << ')'\n"
      code << "    items = items.where(conditions)\n"

      code << "    ordering = ['(']\n"
      code << "    keys.each_with_index do |key, index|\n"
      code << "      ordering[0] << ') AND (' if index > 0\n"
      code << '      ordering[0] << ' + searchable_filters.collect do |column|
        "LOWER(CAST(#{column[:search]} AS VARCHAR)) ILIKE E?"
      end.join(' OR ').inspect + "\n"
      code << '      ordering += [' + searchable_filters.collect do |column|
        column[:start_pattern].inspect.gsub('X', '" + key + "')
                              .gsub(/(^\"\"\s*\+\s*|\s*\+\s*\"\"\s*\+\s*|\s*\+\s*\"\"$)/, '')
      end.join(', ') + "]\n"
      code << "    end\n"
      code << "    ordering[0] << ')'\n"
      code << "    items = items.reorder(ActiveRecord::Base.send(:sanitize_sql_array, ordering)).order(#{order.inspect})\n"
      code << "  end\n"

      code << "  respond_to do |format|\n"
      code << "    format.html { render file: '#{view.relative_path_from(Rails.root)}', locals: { items: items, keys: keys, search: params[:q].to_s.capitalize.strip }, layout: false }\n"
      code << "    format.json { render json: items.collect{ |item| { label: #{item_label}, id: item.id } } }\n"
      code << "    format.xml  { render  xml: items.collect{ |item| { label: #{item_label}, id: item.id } } }\n"
      code << "  end\n"
      code << 'end'
      # code.split("\n").each_with_index{|l, x| puts((x+1).to_s.rjust(4)+": "+l.blue)}
      class_eval(code)
      :unroll
    end

    private

    # Converts parameters to a list of value
    def filterify(object, model, parents = [])
      if object.is_a?(Array)
        object.map { |o| filterify(o, model, parents) }.flatten
      elsif object.is_a?(Hash)
        object.map do |k, v|
          unless reflection = model.reflect_on_association(k)
            raise "Cannot find a reflection #{k} for #{model.name}"
          end
          fmodel = reflection.class_name.constantize
          filterify(v, fmodel, parents + [k.to_sym])
        end.flatten
      elsif object.is_a?(Symbol) || object.is_a?(String)
        infos = object.to_s.split(':')
        name = infos[2] || [parents.last, infos.first].compact.join('_')
        test = parents.each_with_index.map do |_parent, index|
          'item.' + parents[0..index].join('.')
        end
        test << 'item.' + (parents + [infos.first]).join('.')
        filter = {
          name: name.to_sym,
          expression: "((#{test.join(' and ')}) ? #{test.last}.l : '')",
          root: parents.empty?
        }
        return filter if infos.second == '!'
        unless definition = model.columns_definition[infos.first]
          raise "Cannot find column definition for #{model.table_name}##{infos.first}"
        end
        filter[:search]  = "#{model.table_name}.#{infos.first}"
        filter[:pattern] = infos.second || '%X%'
        filter[:start_pattern] = infos.second || 'X%'
        filter[:column_name] = definition.name
        filter[:column_type] = definition.type
        return filter
      else
        raise "What a parameter? #{object.inspect}"
      end
    end

    # Converts parameters to a valid :includes option for ARel
    def includify(object)
      if object.is_a?(Array)
        a = object.map { |o| includify(o) }.compact
        return (a.size == 1 ? a.first : a)
      elsif object.is_a?(Hash)
        n = object.each_with_object({}) do |pair, h|
          h[pair.first] = includify(pair.second)
          h
        end
        return n.each_with_object([]) do |pair, a|
          a << (pair.second.nil? ? pair.first : { pair.first => pair.second })
          a
        end
      elsif object.is_a?(Symbol) || object.is_a?(String)
        return nil
      else
        raise "What a parameter? #{object.inspect}"
      end
    end

    # Converts parameters to a valid :includes option for ARel
    def compactify(object)
      if object.is_a?(Array)
        a = object.map { |o| compactify(o) }.compact
        return (a.empty? ? nil : a)
      elsif object.is_a?(Hash)
        return (object.keys.empty? ? nil : object.each_with_object({}) { |p, h| h[p.first] = compactify(p.second); h })
      elsif object.is_a?(Symbol) || object.is_a?(String)
        return object
      else
        raise "What a parameter? #{object.inspect}"
      end
    end
  end
end
