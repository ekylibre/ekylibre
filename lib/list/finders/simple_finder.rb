module List

  class SimpleFinder < List::Finder


    def select_data_code(table)
      # If Arel is used in Rails we used it
      if table.model.respond_to? :arel_table
        code  = "#{table.records_variable_name} = #{table.model.name}"
        code << ".select(#{select_code(table)})" if select_code(table)
        code << ".where(#{conditions_to_code(table.options[:conditions])})" unless table.options[:conditions].blank?
        code << ".joins(#{table.options[:joins].inspect})" unless table.options[:joins].blank?
        code << ".includes(#{self.includes(table).inspect})"
        code << ".order(order)||{}\n"      
      else
        code  = "#{table.records_variable_name} = #{table.model.name}.find(:all"
        code << ", :select=>#{select_code(table)}" if select_code(table)
        code << ", :conditions=>"+conditions_to_code(table.options[:conditions]) unless table.options[:conditions].blank?
        code << ", :joins=>#{table.options[:joins].inspect}" unless table.options[:joins].blank?
        code << ", :include=>#{self.includes(table).inspect}"
        code << ", :order=>order)||{}\n"
      end
      return code
    end

  end

end


List.register_finder(:simple_finder, List::SimpleFinder)
