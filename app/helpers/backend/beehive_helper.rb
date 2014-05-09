# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple agricultural ERP
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

module Backend::BeehiveHelper

  # 巣 Beehive permits to create modular interface organized in cells
  def beehive(name = nil, &block)
    html = ""
    return html unless block_given?
    name ||= "#{controller_name}_#{action_name}".to_sym
    board = Beehive.new(name, self)
    if block.arity < 1
      board.instance_eval(&block)
    else
      block[board]
    end
    return render(partial: "backend/shared/beehive", object: board)
  end

  class Beehive
    attr_reader :name, :boxes, :template

    class TabBox < Array
      def self.short_name
        "tab"
      end
    end

    class HorizontalBox < Array
      def self.short_name
        "h"
      end
    end

    class Cell
      attr_reader :content, :name, :beehive, :options, :type

      def initialize(name, beehive, options = {}, &block)
        @name = name
        @type = options[:type] || @name
        @beehive = beehive
        @options = options
        if block_given?
          @content = @beehive.template.capture(&block)
          @has_content = true
        end
      end

      def content?
        !!@has_content
      end

      def title
        @options[:title] || (@name.is_a?(String) ? @name : ::I18n.t("labels.#{@name}", @options.merge(:default => @name.to_s.humanize)))
      end
    end

    def initialize(name, template)
      @name = name
      @boxes = []
      @current_box = nil
      @template = template
    end

    def cell(name = :details, options = {}, &block)
      c = Cell.new(name, self, options, &block)
      if @current_box
        @current_box << c
      else
        box = HorizontalBox.new
        box << c
        @boxes << box
      end
    end

    def hbox(&block)
      return box(:horizontal, &block)
    end

    def tabbox(&block)
      return box(:tab, &block)
    end

    protected

    def box(type, &block)
      if @current_box
        raise StandardError, "Cannot define box in other box"
      end
      @current_box = (type == :tab ? TabBox : HorizontalBox).new
      block[self] if block_given?
      @boxes << @current_box unless @current_box.empty?
      @current_box = nil
    end

  end

end
