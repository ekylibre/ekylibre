module Kame

  class SimpleFinder < Kame::Finder


    def select_data_code(table)
      # If Arel is used in Rails we used it
      if table.model.respond_to? :arel_table
        code  = "#{table.records_variable_name} = #{table.model.name}"
        code += ".select('DISTINCT #{table.model.table_name}.*')" if table.options[:distinct]
        code += ".where(#{conditions_to_code(table.options[:conditions])})" unless table.options[:conditions].blank?
        code += ".joins(#{table.options[:joins].inspect})" unless table.options[:joins].blank?
        code += ".order(order)||{}\n"      
      else
        code  = "#{table.records_variable_name} = #{table.model.name}.find(:all"
        code += ", :select=>'DISTINCT #{table.model.table_name}.*'" if table.options[:distinct]
        code += ", :conditions=>"+conditions_to_code(table.options[:conditions]) unless table.options[:conditions].blank?
        code += ", :joins=>#{table.options[:joins].inspect}" unless table.options[:joins].blank?
        code += ", :order=>order)||{}\n"
      end
      return code
    end

  end

end


Kame.register_finder(:simple_finder, Kame::SimpleFinder)
