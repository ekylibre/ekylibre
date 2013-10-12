# encoding: UTF-8
module ActiveList

  class Generator

    attr_accessor :table, :controller, :controller_method_name, :view_method_name, :records_variable_name

    def initialize(*args, &block)
      options = args.extract_options!
      @controller = options[:controller]
      name = args.shift || @controller.controller_name.to_sym
      model = (options[:model]||name).to_s.classify.constantize
      @controller_method_name = "list#{'_'+name.to_s if name != @controller.controller_name.to_sym}"
      @view_method_name       = "_#{@controller.controller_name}_list_#{name}_tag"
      @records_variable_name  = "@#{name}"
      @table = ActiveList::Definition::Table.new(name, model, options)
      if block_given?
        yield @table
      else
        @table.load_default_columns
      end
      @parameters = {:sort => :to_s, :dir => :to_s}
      @parameters.merge!(:page => :to_i, :per_page => :to_i) if @table.paginate?
    end

    def var_name(name)
      "the_#{name}"
    end

    def renderer
      ActiveList::Renderers[@table.options[:renderer]].new(self)
    end

    def controller_method_code
      code  = "# encoding: utf-8\n"
      code << "def #{self.controller_method_name}\n"
      code << self.session_initialization_code.dig
      code << "  respond_to do |format|\n"
      code << "    format.html do\n"
      code << "      if request.xhr?\n"
      code << self.renderer.remote_update_code.dig(4)
      code << "      else\n"
      code << "        render(inline: '<%=#{self.view_method_name}-%>', layout: true)\n"
      code << "      end\n"
      code << "    end\n"
      for format, exporter in ActiveList::Exporters.hash
        code << "    format.#{format} do\n"
        code << exporter.new(self).send_data_code.dig(3)
        code << "    end\n"
      end
      code << "  end\n"
      # Save preferences of user
      code << "  p = current_user.pref('list.#{self.view_method_name}', YAML::dump(#{var_name(:params)}))\n"
      code << "  p.set! YAML::dump(#{var_name(:params)})\n"
      code << "end\n"
      # code.split("\n").each_with_index{|l, x| puts((x+1).to_s.rjust(4)+": "+l)}
      if Rails.env.development?
        file = Rails.root.join("tmp", "code", "active-list", "controllers", self.controller.controller_path, self.controller_method_name + ".rb")
        FileUtils.mkdir_p(file.dirname)
        File.write(file, code)
      end
      return code
    end

    def view_method_code
      code  = "# encoding: utf-8\n"
      code << "def #{self.view_method_name}(options={}, &block)\n"
      code << self.session_initialization_code.dig
      code << self.renderer.build_table_code.dig
      code << "end\n"
      # code.split("\n").each_with_index{|l, x| puts((x+1).to_s.rjust(4)+": "+l)}
      if Rails.env.development?
        file = Rails.root.join("tmp", "code", "active-list", "views", self.controller.controller_path, self.view_method_name + ".rb")
        FileUtils.mkdir_p(file.dirname)
        File.write(file, code)
      end
      return code
    end


    def session_initialization_code
      code  = "options = {} unless options.is_a? Hash\n"
      code << "options.update(params)\n"
      code << "#{var_name(:params)} = YAML::load(current_user.pref('list.#{self.view_method_name}', YAML::dump({})).value)\n"
      code << "#{var_name(:params)} = {} unless #{var_name(:params)}.is_a?(Hash)\n"
      code << "unless #{var_name(:params)}[:hidden_columns].is_a? Array\n"
      code << "  #{var_name(:params)}[:hidden_columns] = #{@table.hidden_columns.map(&:name).map(&:to_sym).inspect}\n"
      code << "end\n"
      for parameter, convertor in @parameters.sort{|a,b| a[0].to_s <=> b[0].to_s}
        expr = "options.delete('#{@table.name}_#{parameter}') || options.delete('#{parameter}') || #{var_name(:params)}[:#{parameter}]"
        expr += " || #{@table.options[parameter]}" unless @table.options[parameter].blank?
        code << "#{var_name(:params)}[:#{parameter}] = (#{expr}).#{convertor}\n"
      end
      # Order
      code << "#{var_name(:order)} = #{@table.options[:order] ? @table.options[:order].inspect : 'nil'}\n"
      code << "if #{var_name(:col)} = {" + @table.sortable_columns.collect{|c| "'#{c.sort_id}' => '#{c.name}'"}.join(', ') + "}[#{var_name(:params)}[:sort]]\n"
      code << "  #{var_name(:params)}[:dir] = 'ASC' unless #{var_name(:params)}[:dir] == 'asc' or #{var_name(:params)}[:dir] == 'desc'\n"
      code << "  #{var_name(:order)} = #{@table.model.name}.connection.quote_column_name(#{var_name(:col)}) + ' ' + #{var_name(:params)}[:dir]\n"
      code << "end\n"

      return code
    end

  end

end

require "active-list/generator/finder"
