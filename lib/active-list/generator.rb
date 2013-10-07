# encoding: UTF-8
require "active-list/finder"
require "active-list/exporters"
require "active-list/renderers"

module ActiveList

  class Table

    def view_method_name
      @options[:view_method_name]
    end

    def controller_method_name
      @options[:controller_method_name]
    end

    def records_variable_name
      @options[:records_variable_name]
    end

    def var_name(name)
      "the_#{name}"
    end

    def controller
      @options[:controller]
    end

    def renderer
      ActiveList.renderers[@options[:renderer]].new(self)
    end


    def generate_controller_method_code
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
      for format, exporter in ActiveList.exporters
        code << "    format.#{format} do\n"
        code << exporter.send_data_code(self).dig(3)
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

    def generate_view_method_code
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
      # Session values
      # code << "session[:list] = {} unless session[:list].is_a? Hash\n"
      # code << "session[:list][:#{self.view_method_name}] = {} unless session[:list][:#{self.view_method_name}].is_a? Hash\n"
      code << "#{var_name(:params)} = YAML::load(current_user.pref('list.#{self.view_method_name}', YAML::dump({})).value)\n"
      code << "#{var_name(:params)} = {} unless #{var_name(:params)}.is_a?(Hash)\n"
      code << "unless #{var_name(:params)}[:hidden_columns].is_a? Array\n"
      code << "  #{var_name(:params)}[:hidden_columns] = #{self.hidden_columns.map(&:name).map(&:to_s).inspect}\n"
      code << "end\n"
      for parameter, convertor in @parameters.sort{|a,b| a[0].to_s <=> b[0].to_s}
        expr = "options.delete('#{self.name}_#{parameter}') || options.delete('#{parameter}') || #{var_name(:params)}[:#{parameter}]"
        expr += " || #{@options[parameter]}" unless @options[parameter].blank?
        code << "#{var_name(:params)}[:#{parameter}] = (#{expr}).#{convertor}\n"
      end
      # Order
      code << "#{var_name(:order)} = #{self.options[:order] ? self.options[:order].inspect : 'nil'}\n"
      code << "if col = {"+self.sortable_columns.collect{|c| "#{c.sort_id}: '#{c.name}'"}.join(', ')+"}[#{var_name(:params)}[:sort]]\n"
      code << "  #{var_name(:params)}[:dir] = 'ASC' unless #{var_name(:params)}[:dir] == 'asc' or #{var_name(:params)}[:dir] == 'desc'\n"
      code << "  order = #{@model.name}.connection.quote_column_name(col) + ' ' + #{var_name(:params)}[:dir]\n"
      code << "end\n"

      return code
    end


  end
end
