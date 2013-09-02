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

    def renderer
      ActiveList.renderers[@options[:renderer]]
    end
    

    def generate_controller_method_code
      code  = "# encoding: utf-8\n"
      code << "def #{self.controller_method_name}\n"
      code << self.session_initialization_code.gsub(/^/, '  ')
      code << "  respond_to do |format|\n"
      code << "    format.html do\n"
      code << "      if request.xhr?\n"
      code << self.renderer.remote_update_code(self).gsub(/^/, '        ')
      code << "      else\n"
      code << "        render(:inline=>'<%=#{self.view_method_name}-%>', :layout=>true)\n"
      code << "      end\n"
      code << "    end\n"
      for format, exporter in ActiveList.exporters
        code << "    format.#{format} do\n"
        code << exporter.send_data_code(self).gsub(/^/, '      ')
        code << "    end\n"
      end
      code << "  end\n"
      code << "end\n"
      # code.split("\n").each_with_index{|l, x| puts((x+1).to_s.rjust(4)+": "+l)}
      return code
    end

    def generate_view_method_code
      code  = "# encoding: utf-8\n"
      code << "def #{self.view_method_name}(options={}, &block)\n"
      code << self.session_initialization_code.gsub(/^/, '  ')
      code << self.renderer.build_table_code(self).gsub(/^/, '  ')
      code << "end\n"
      # code.split("\n").each_with_index{|l, x| puts((x+1).to_s.rjust(4)+": "+l)}
      return code      
    end


    def session_initialization_code
      code  = "options = {} unless options.is_a? Hash\n"
      code << "options = (params||{}).merge(options)\n"
      # Session values
      code << "session[:list] = {} unless session[:list].is_a? Hash\n"
      code << "session[:list][:#{self.view_method_name}] = {} unless session[:list][:#{self.view_method_name}].is_a? Hash\n"      
      code << "list_params = session[:list][:#{self.view_method_name}]\n"
      code << "list_params[:hidden_columns] = [] unless list_params[:hidden_columns].is_a? Array\n"
      for parameter, convertor in @parameters.sort{|a,b| a[0].to_s <=> b[0].to_s}
        expr = "options.delete('#{self.name}_#{parameter}') || options.delete('#{parameter}') || list_params[:#{parameter}]"
        expr += " || #{@options[parameter]}" unless @options[parameter].blank?
        code << "list_params[:#{parameter}] = (#{expr}).#{convertor}\n"
      end
      # Order
      code << "order = #{self.options[:order] ? self.options[:order].inspect : 'nil'}\n"
      code << "if (col = {"+self.sortable_columns.collect{|c| "'#{c.id}'=>'#{c.name}'"}.join(', ')+"}[list_params[:sort]])\n"
      code << "  list_params[:dir] ||= 'asc'\n"
      code << "  if list_params[:dir] == 'asc' or list_params[:dir] == 'desc'\n"
      code << "    order = #{@model.name}.connection.quote_column_name(col)+' '+list_params[:dir]\n"
      code << "  end\n"
      code << "end\n"

      return code
    end


  end
end
