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
    options = (args[-1].is_a?(Hash) ? args.delete_at(-1) : {})
    menu = Menu.new
    yield menu

    name = args[0]

    html = "".html_safe
    for args in menu.items
      name = args[0]
      args[1] ||= {}
      args[2] ||= {}
      li_options = {}
      if args[2].delete(:active)
        li_options[:class] = 'active'
      end
      if name.is_a?(Symbol)
        kontroller = (args[1].is_a?(Hash) ? args[1][:controller] : nil) || controller_name
        args[0] = ::I18n.t("actions.#{kontroller}.#{name}".to_sym, {:default => ["labels.#{name}".to_sym]}.merge(args[2].delete(:i18n)||{}))
      end
      if icon = args[2].delete(:icon)
        args[0] = content_tag(:i, '', :class => "icon-"+icon.to_s) + ' '.html_safe + h(args[0])
      end
      if name.is_a? Symbol and name!=:back
        args[1][:action] ||= name if args[1].is_a?(Hash)
      end
      html << content_tag(:li, link_to(*args), li_options) if authorized?(args[1])
    end
    html = content_tag(:ul, html) unless html.blank?

    content_for(:aside) do
      snippet(name) do
        html
      end
    end unless html.blank?


    # html = content_tag(:h3, content_tag(:i) + h(name.is_a?(Symbol) ? tl("menus.#{name}", :default => name.to_s.humanize) : name.to_s)) + html unless html.blank?

    # content_for(:aside, content_tag(:div, html.html_safe, :class => "side-menu side-menu-#{name}")) unless html.blank?

    return nil
  end

  class Menu
    attr_reader :items

    def initialize
      @items = []
    end

    def link(name, *args)
      @items << [name, *args]
    end
  end


  def snippet(name, options={}, &block)
    session[:snippets] ||= {}
    session[:snippets][name.to_s] = true unless [TrueClass, FalseClass].include?(session[:snippets][name.to_s].class)
    shown = session[:snippets][name]
    html = ""
    html << "<div class='snippet#{' '+options[:class].to_s if options[:class]}#{' collapsed' unless shown}'>"
    html << "<div class='snippet-title'>"
    html << link_to("", "#", "data-toggle-snippet" => name, :class => (shown ? :hide : :show))
    # html << link_to("", {:action => :toggle_snippet, :controller => :interfacers}, "data-toggle-snippet" => name, :class => (shown ? :hide : :show))
    html << "<h3><i></i>" + (options[:title]||tl(name)) + "</h3>"
    html << "</div>"
    html << "<div class='snippet-content'" + (shown ? '' : ' style="display: none"') + ">"
    begin
      html << capture(&block)
    rescue Exception => e
      html << content_tag(:small, "#{e.class.name}: #{e.message}")
    end
    html << "</div>"
    html << "</div>"
    return html.html_safe
  end


end
