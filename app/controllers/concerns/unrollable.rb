module Unrollable
  extend ActiveSupport::Concern

  module ClassMethods

    # Create unroll action for all scopes in the model corresponding to the controller
    # including the default scope
    def unroll(options = {})
      model = (options.delete(:model) || controller_name).to_s.classify.constantize
      foreign_record  = model.name.underscore
      foreign_records = foreign_record.pluralize
      scope_name = options.delete(:scope) || name
      max = options[:max] || 80
      available_methods = model.columns_definition.keys.map(&:to_sym)
      if label = options.delete(:label)
        label = (label.is_a?(Symbol) ? "{#{label}:%X%}" : label.to_s)
      else
        # base = "unroll." + self.controller_path
        # label = I18n.translate(base + ".#{name || :all}", :default => [(base + ".all").to_sym, ""])
        label = I18n.translate("unrolls." + self.controller_path, :default => "")
        if label.blank?
          label = '{' + [:title, :label, :full_name, :name, :code, :number].select{|x| available_methods.include?(x)}.first.to_s + ':%X%}'
        end
      end

      unless order = options[:order]
        order = [:title, :label, :full_name, :name, :code, :number].detect{|x| available_methods.include?(x)}
        order ||= :id
      end

      columns = []
      item_label = label.inspect.gsub(/\{\!?[a-z\_\.]+(\:\%?X\%?)?\}/) do |word|
        ca = word[1..-2].split(":")
        name = ca.first
        i = nil
        if name =~ /\A\!/
          i = "item." + name.gsub!(/\A\!/, '')
        else
          if name =~ /\./
            i = "item.#{name}"
            array = name.split(/\./)
            fmodel = model
            for step in array[0..-2]
              fmodel = fmodel.reflections[step.to_sym].class_name.constantize
            end
            columns << {name: name.gsub(/\W/, '_'), search: fmodel.table_name + "." + array[-1], filter: ca.second || "X%"}
          elsif column = model.columns_definition[name]
            i = "item.#{name}"
            columns << column.options.merge(search: "#{model.table_name}.#{name}", filter: ca.second || "X%")
          else
            raise StandardError, "Cannot handle #{name} for #{model.name}"
          end
        end
        steps = i.to_s.split('.')
        expr = (0..(steps.size - 1)).to_a.collect do |s|
          steps[0..s].join(".")
        end
        "\" + ((#{expr.join(' and ')}) ? #{i}.l : '') + \""
      end
      item_label.gsub!(/\A\"\"\s*\+\s*/, '')
      item_label.gsub!(/\s*\+\s*\"\"\z/, '')

      fill_in = (options.has_key?(:fill_in) ? options[:fill_in] : columns.size == 1 ? columns.first[:name] : model.columns_definition["name"] ? :name : nil)
      fill_in = fill_in.to_sym unless fill_in.nil?

      if !fill_in.nil? and !columns.detect{|c| c[:name] == fill_in }
        raise StandardError.new("Label (#{label}, #{columns.inspect}) of unroll must include the primary column: #{fill_in.inspect}")
      end

      haml  = ""
      haml << "- if items.any?\n"
      haml << "  %ul.items-list\n"
      haml << "    - for item in items.limit(items.count > #{(max*1.5).round} ? #{max} : #{max*2})\n"
      haml << "      %li.item{'data-item-label' => #{item_label}, 'data-item-id' => item.id}\n"
      if options[:partial]
        haml << "        = render '#{partial}', :item => item\n"
      else
        haml << "        = highlight(#{item_label}, keys)\n"
      end
      haml << "  - if items.count > #{(max*1.5).round}\n"
      haml << "    %span.items-status.items-status-too-many-records\n"
      haml << "      = 'labels.x_items_remain'.t(count: (items.count - #{max}))\n"
      haml << "- else\n"
      haml << "  %ul.items-list\n"
      unless fill_in.nil?
        haml << "    - unless search.blank?\n"
        haml << "      %li.item.special{'data-new-item' => search, 'data-new-item-parameter' => '#{fill_in}'}= I18n.t('labels.add_x', :x => content_tag(:strong, search)).html_safe\n"
      end
      haml << "    %li.item.special{'data-new-item' => ''}= I18n.t('labels.add_#{model.name.underscore}', :default => [:'labels.add_new_record'])\n"
      # haml << "  %span.items-status.items-status-empty\n"
      # haml << "    =I18n.t('labels.no_results')\n"

      # Write haml in cache
      path = self.controller_path.split('/')
      path[-1] << ".html.haml"
      view = Rails.root.join("tmp", "cache", "unroll", *path)
      FileUtils.mkdir_p(view.dirname)
      File.open(view, "wb") do |f|
        f.write(haml)
      end

      code  = "def unroll\n"
      code << "  conditions = []\n"

      code << "  klass = controller_name.classify.constantize\n"
      code << "  items = klass.unscoped"
      if options[:includes]
        code << ".includes(#{options[:includes].inspect})"
        code << ".references(#{options[:includes].inspect})"
      end
      code <<  ".order(#{order.inspect})\n"
      # code << "  items = #{model.name}.unscoped\n"
      # code << "  raise params[:scope].inspect\n"
      code << "  if scopes = params[:scope]\n"
      code << "    scopes = {scopes.to_sym => true} if scopes.is_a?(String)\n"
      code << "    for scope, parameters in scopes.symbolize_keys\n"
      code << "      if (parameters.is_a?(TrueClass) or parameters == 'true') and klass.simple_scopes.map(&:name).include?(scope)\n"
      code << "        items = items.send(scope)\n"
      code << "      elsif parameters.is_a?(String) and klass.complex_scopes.map(&:name).include?(scope)\n"
      code << "        items = items.send(scope, *(parameters.strip.split(/\s*\,\s*/)))\n"
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
      code << "    items = items.where(id: params[:id])\n"
      searchable_columns = columns.delete_if{ |c| c[:type] == :boolean }
      if searchable_columns.size > 0
        code << "  elsif keys.size > 0\n"
        code << "    conditions = ['(']\n"
        code << "    keys.each_with_index do |key, index|\n"
        code << "      conditions[0] << ') AND (' if index > 0\n"
        code << "      conditions[0] << " + searchable_columns.collect do |column|
          "LOWER(CAST(#{column[:search]} AS VARCHAR)) ~ E?"
        end.join(' OR ').inspect + "\n"
        code << "      conditions += [" + searchable_columns.collect do |column|
          column[:filter].inspect.gsub('X', '" + key + "').gsub('%', '')
            .gsub(/(^\"\"\s*\+\s*|\s*\+\s*\"\"\s*\+\s*|\s*\+\s*\"\"$)/, '')
        end.join(", ") + "]\n"
        code << "    end\n"
        code << "    conditions[0] << ')'\n"
        code << "    items = items.where(conditions)\n"
      else
        logger.error("No searchable columns for #{self.controller_path}#unroll")
      end
      code << "  end\n"

      code << "  respond_to do |format|\n"
      code << "    format.html { render file: '#{view.relative_path_from(Rails.root)}', :locals => { items: items, keys: keys, search: params[:q].to_s.capitalize.strip }, layout: false }\n"
      code << "    format.json { render json: items.collect{|item| {label: #{item_label}, id: item.id}} }\n"
      code << "    format.xml  { render  xml: items.collect{|item| {label: #{item_label}, id: item.id}} }\n"
      code << "  end\n"
      code << "end"
      # code.split("\n").each_with_index{|l, x| puts((x+1).to_s.rjust(4)+": "+l)}
      class_eval(code)
      return :unroll
    end

  end

end
