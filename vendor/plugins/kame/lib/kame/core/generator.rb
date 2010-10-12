module Kame

  class Table

    def view_method_name
      Kame.view_method_name(self.name)
    end

    def controller_method_name
      Kame.controller_method_name(self.name)
    end

    def records_variable_name
      Kame.records_variable_name(self.name)
    end


    protected

    

    def generate_controller_method_code
      code  = "def #{Kame.controller_method_name(self.name)}\n"
      # Maximum priority action
      code += "  if request.xhr?\n"
      code += "    render(:inline=>'<%=#{Kame.view_method_name(self.name)}->')\n"
      # Actions
      for format, exporter in Kame.exporters
        code += "  elsif (params[:format] == '#{format}')\n"
        code += "    #{Kame::SimpleFinder.select_data_code(self)}\n"
        code += "    #{exporter.format_data_code(self, 'data')}\n"
        code += "    send_data(data, :type=>#{exporter.mime_type}, :disposition=>'inline', :filename=>#{table.model.name}.model_name.human.gsub(/[^a-z0-9]/i,'_')+'.#{exporter.file_extension}')\n"
      end
      # Minimum priority action
      code += "  else\n"
      code += "    render(:inline=>'<%=#{Kame.view_method_name(self.name)}->', :layout=>true)\n"
      code += "  end\n"
      code += "end"
      return code
    end

    def generate_view_method_code
      code  = "def #{Kame.view_method_name(self.name)}\n"
      code += self.options[:finder].select_data_code
      code += self.options[:renderer].build_table_code
      code  = "end\n"
      return code      
    end



  end
end
