module Kame

  class WillPaginateFinder < Kame::Finder
    
    def select_data_code(table)
      # Check order
      unless table.options.keys.include?(:order)
        columns = table.table_columns
        if columns.size > 0
          options[:order] = table.model.connection.quote_column_name(columns[0].name.to_s)
        else
          raise ArgumentError.new("Option :order is needed for the Kame :#{table.name}")
        end
      end


      # Search for an existing used page
      code  = "  page = (options[:page]||session[:dyta][:#{table.name}][:page]||1).to_i\n"
      code += "  session[:dyta][:#{table.name}][:page] = page\n"
      # Find data
      code += "  #{table.records_variable_name} = #{table.model.name}.paginate(:all"
      code += ", :select=>'DISTINCT #{table.model.table_name}.*'" if table.options[:distinct]
      code += ", :conditions=>"+conditions_to_code(table.options[:conditions]) unless table.options[:conditions].blank?
      code += ", :page=>page, :per_page=>options['#{name}_per_page']||"+(table.options[:per_page]||25).to_s
      code += ", :joins=>#{table.options[:joins].inspect}" unless table.options[:joins].blank?
      code += ", :order=>order#{default_order})||{}\n"
      code += "  return #{table.view_method_name}(options.merge(:page=>1)) if page>1 and #{table.records_variable_name}.out_of_bounds?\n"

      return code
    end


  end

end

Kame.register_finder(:will_paginate, Kame::WillPaginateFinder)
