# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2008-2013 Brice Texier
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

module BackendHelper

  def bar_chart(values, options = {})
    render :partial => "backend/charts/bar_chart", :locals => {:values => values}
  end

  def pie_chart(values, options = {})
    render :partial => "backend/charts/pie_chart", :locals => {:values => values}
  end

  # Angles are in degrees (not in radians)
  def pie_piece_path(x, y, radius, angle_start, angle_stop)
    # M 320,240 L 414.96396989003193,208.66560320151174 A 100,100,0,0,1, 361.91765204166643,330.7904755319289Z
    angle = angle_stop - angle_start
    path = "M#{x},#{y}"
    path << "L#{x + radius.to_f*Math.cos(angle_start*Math::PI/180.0)},#{y + radius.to_f*Math.sin(angle_start*Math::PI/180.0)}"
    path << "A#{radius},#{radius},#{angle_start},"
    path << (angle > 180 ? "1" : "0") + ","
    path << "1,"
    path << "#{x + radius.to_f*Math.cos(angle_stop*Math::PI/180.0)},#{y + radius.to_f*Math.sin(angle_stop*Math::PI/180.0)}"
    path << "Z"
    return path
  end


  def root_models
    Ekylibre.references.keys.collect{|a| [::I18n.t("activerecord.models.#{a.to_s.singularize}"), a.to_s.singularize]}.sort{|a,b| a[0].ascii <=> b[0].ascii}
  end

  def navigation_tag
    session[:last_page] ||= {}
    render :partial => "layouts/navigation"
  end


  def side_tag # (submenu = self.controller.controller_name.to_sym)
    path = reverse_menus
    return '' if path.nil?
    render(:partial => 'layouts/side', :locals => {:path => path})
  end

  def side_menu(*args, &block)
    return "" unless block_given?
    main_options = (args[-1].is_a?(Hash) ? args.delete_at(-1) : {})
    menu = Menu.new
    yield menu

    main_name = args[0].to_s.to_sym
    main_options[:icon] ||= main_name.to_s.parameterize.gsub(/\_/, '-')

    html = "".html_safe
    for name, url, options in menu.items
      li_options = {}
      li_options[:class] = 'active' if options.delete(:active)

      kontroller = (url.is_a?(Hash) ? url[:controller] : nil) || controller_name
      options[:title] ||= ::I18n.t("actions.#{kontroller}.#{name}".to_sym, {:default => ["labels.#{name}".to_sym]}.merge(options.delete(:i18n)||{}))
      if icon = options.delete(:icon)
        item[:title] = content_tag(:i, '', :class => "icon-" + icon.to_s) + ' '.html_safe + h(item[:title])
      end
      if name != :back
        url[:action] ||= name if url.is_a?(Hash)
      end
      html << content_tag(:li, link_to(options[:title], url, options), li_options) if authorized?(url)
    end

    unless html.blank?
      html = content_tag(:ul, html)
      snippet(main_name, main_options) { html }
    end 

    return nil
  end

  class Menu
    attr_reader :items

    def initialize
      @items = []
    end

    def link(name, url = {}, options = {})
      @items << [name, url, options]
    end
  end


  def snippet(name, options={}, &block)
    collapsed = current_user.preference("interface.snippets.#{name}.collapsed", false, :boolean).value
    # raise collapsed.value.inspect unless options[:title].is_a?(FalseClass)
      # .value
    collapsed = false if collapsed and options[:title].is_a?(FalseClass)

    options[:class] ||= ""
    options[:class] << " snippet-#{options[:icon]}"

    html = ""
    html << "<div id='#{name}' class='snippet#{' ' + options[:class].to_s if options[:class]}#{' collapsed' if collapsed}'>"

    unless options[:title].is_a?(FalseClass)
      html << "<a href='#{url_for(:controller => :snippets, :action => :toggle, :id => name)}' class='snippet-title' data-toggle-snippet='true'>"
      html << "<i class='collapser'></i>"
      html << "<h3><i></i>" + (options[:title] || tl(name)) + "</h3>"
      html << "</a>"
    end

    html << "<div class='snippet-content'" + (collapsed ? ' style="display: none"' : '') + ">"
    begin
      html << capture(&block)
    rescue Exception => e
      html << content_tag(:small, "#{e.class.name}: #{e.message}")
    end
    html << "</div>"

    html << "</div>"
    content_for(:aside, html.html_safe)
    return nil
  end


end
