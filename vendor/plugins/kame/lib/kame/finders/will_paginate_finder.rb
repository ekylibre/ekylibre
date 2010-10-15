module Kame

  class WillPaginateFinder < Kame::Finder
    
    def select_data_code(table)
      # Check order
      unless table.options.keys.include?(:order)
        columns = table.table_columns
        if columns.size > 0
          table.options[:order] = table.model.connection.quote_column_name(columns[0].name.to_s)
        else
          raise ArgumentError.new("Option :order is needed for the Kame :#{table.name}")
        end
      end

      default_order = (table.options[:order] ? '||'+table.options[:order].inspect : '')

      # Search for an existing used page
      code  = "page = (options[:page]||kame_params[:page]||1).to_i\n"
      code += "kame_params[:page] = page\n"
      # Find data
      code += "#{table.records_variable_name} = #{table.model.name}.paginate(:all"
      code += ", :select=>'DISTINCT #{table.model.table_name}.*'" if table.options[:distinct]
      code += ", :conditions=>"+conditions_to_code(table.options[:conditions]) unless table.options[:conditions].blank?
      code += ", :page=>page, :per_page=>kame_params[:per_page]"
      code += ", :joins=>#{table.options[:joins].inspect}" unless table.options[:joins].blank?
      code += ", :order=>order#{default_order})||{}\n"
      code += "return #{table.view_method_name}(options.merge(:page=>1)) if page>1 and #{table.records_variable_name}.out_of_bounds?\n"

      return code
    end

    def paginate?
      true
    end


  end

end


if defined? WillPaginate
  Kame.register_finder(:will_paginate_finder, Kame::WillPaginateFinder)

  ERB::Util::HTML_ESCAPE.merge( '&' => '&#38;', '>' => '&#62;', '<' => '&#60;', '"' => '&#34;' )

  module ActionView
    class RemoteLinkRenderer < WillPaginate::ViewHelpers::LinkRenderer
      
      def initialize
        @gap_marker = '<span class="gap">&#8230;</span>'
      end

      def prepare(collection, options, template)
        @remote = options.delete(:remote) || {}
        super
      end

      protected

      # WillPaginate 2
      def page_link(page, text, attributes = {})
        @template.link_to_remote(text, {:url => url_for(page), :method => :get}.merge(@remote), attributes)
      end

      # WillPaginate 3
      def link(text, target, attributes = {})
        if target.is_a? Fixnum
          attributes[:rel] = rel_value(target)
          target = url(target)
        end
        attributes[:href] = target
        @template.link_to_remote(text, {:url => target, :method => :get}.merge(@remote), attributes)
      end

    end  
  end

end


