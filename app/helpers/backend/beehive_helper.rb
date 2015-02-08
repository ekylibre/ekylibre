# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2013 Brice Texier
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
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
    layout = board.to_hash
    if preference = current_user.preferences.find_by(name: board.preference_name)
      layout = YAML.load(preference.value).deep_symbolize_keys
    end
    return render(partial: "backend/shared/beehive", object: board, locals: {layout: layout})
  end

  class Beehive
    class Box < Array
      def self.short_name
        raise NotImplementedError
      end

      def to_hash
        { type: self.class.short_name, children: map(&:to_hash) }
      end
    end


    class HorizontalBox < Box
      def self.short_name
        "hbox"
      end
    end

    class Cell
      attr_reader :content, :name, :options

      def initialize(name, options = {})
        unless name.is_a?(Symbol)
          raise "Only symbol for cell name. Use :title option to specify title."
        end
        @name = name
        @options = options
        @content = @options.delete(:content)
        @i18n = @options.delete(:i18n) || @options
      end

      def content?
        !@content.blank?
      end

      def title
        @options[:title].is_a?(Symbol) ? @options[:title].tl(@i18n.merge(default: @name.to_s.humanize)) : (@options[:title] || @name.tl(@i18n.merge(default: @name.to_s.humanize)))
      end

      def to_hash
        hash = { type: "cell", name: @name.to_s }
        hash[:options] = @options unless @options.empty?
        hash
      end
    end


    attr_reader :name, :template

    def initialize(name, template)
      @name = name
      @children = []
      @cells = {}.with_indifferent_access
      @current_box = nil
      @template = template
    end

    cattr_reader :controller_cells
    def self.controller_cells
      unless @controller_cells
        Dir.chdir(Rails.root.join('app/controllers/backend/cells')) do
          @controller_cells = Dir["*_controller.rb"].map do |path|
            path.gsub(/_cells_controller.rb$/, '').to_sym
          end.compact
        end
      end
      return @controller_cells
    end

    # Adds a cell in the beehive
    # Adds a box too if not defined
    def cell(name = :details, options = {}, &block)
      if @current_box
        if block_given?
          options[:content] = @template.capture(&block)
        end
        c = Cell.new(name, options)
        @cells[c.name] = c
        @current_box << c
      else
        hbox do
          cell(name, options, &block)
        end
      end
    end

    def hbox(&block)
      return box(:horizontal, &block)
    end

    def to_hash
      { type: "root", children: @children.map(&:to_hash) }
    end

    def boxes
      @children
    end

    def id
      "beehive-#{@name}"
    end

    def preference_name
      "beehive.#{@name}"
    end

    def find_cell(name)
      @cells[name]
    end

    def local_cells
      @cells.values.select{|c| c.content? }
    end

    def available_cells
      return (self.class.controller_cells + @cells.keys).map(&:to_s).uniq.map do |x|
        [x.tl, x]
      end.sort do |a,b|
        a.first <=> b.first
      end
    end

    protected

    def box(type, &block)
      if @current_box
        raise StandardError, "Cannot define box in other box"
      end
      old_current_box = @current_box
      if block_given?
        @current_box = HorizontalBox.new
        block[self]
        @children << @current_box unless @current_box.empty?
      end
      @current_box = old_current_box
    end

  end

end
