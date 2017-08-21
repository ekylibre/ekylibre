# coding: utf-8

# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2015 Brice Texier
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

module Backend
  module BeehiveHelper
    FORMAT_VERSION = 2

    # 巣 Beehive permits to create modular interface organized in cells
    def beehive(name = nil, &block)
      html = ''
      # return html unless block_given?
      name ||= "#{controller_name}_#{action_name}".to_sym
      board = Beehive.new(name, self)
      if block_given?
        if block.arity < 1
          board.instance_eval(&block)
        else
          block[board]
        end
      end
      render(partial: 'backend/shared/beehive', object: board)
    end

    # Permits to display cell content independently
    def cell(type, options = {}, html_options = {})
      url = options[:params] || {}
      content_tag(:div, nil, html_options.merge(
                               data: {
                                 cell: url_for(url.merge(controller: "backend/cells/#{type}_cells", action: :show)),
                                 cell_empty_message: :no_data.tl,
                                 cell_error_message: :internal_error.tl
                               }
      ))
    end

    class Beehive
      class Box < Array
        def self.short_name
          'box'
        end

        def to_hash
          { cells: map(&:to_hash) }
        end
      end

      class Cell
        attr_reader :content, :type, :options, :name

        cattr_reader :controller_types
        def self.controller_types
          unless @controller_types
            Dir.chdir(Rails.root.join('app/controllers/backend/cells')) do
              @controller_types = Dir['*_cells_controller.rb'].map do |path|
                path.gsub(/_cells_controller.rb$/, '').to_sym
              end.compact
            end
          end
          @controller_types
        end

        def initialize(name, options = {})
          unless name.is_a?(Symbol)
            raise 'Only symbol for cell name. Use :title option to specify title.'
          end
          @name = name.to_sym
          @options = options
          @type = @options.delete(:type) || @name
          @has_content = @options.key?(:content)
          @content = @options.delete(:content)
          @i18n = @options.delete(:i18n) || @options
          if self.class.controller_types.include?(@type)
            raise "Local type cannot be: #{@type}. Already taken." if content?
          elsif !content?
            raise "Invalid cell. Need content or a valid controller cell name (Not #{@name} alone)"
          end
        end

        def content?
          @has_content
        end

        def title
          @options[:title].is_a?(Symbol) ? @options[:title].tl(@i18n) : (@options[:title] || @name.tl(@i18n))
        end

        def to_hash
          { name: @name.to_s, type: @type.to_s, options: @options }
        end
      end

      attr_reader :name, :boxes, :cells

      def initialize(name, template)
        @name = name
        @boxes = []
        @cells = {}.with_indifferent_access
        @current_box = nil
        @template = template
      end

      # Adds a cell in the beehive
      # Adds a box too if not defined
      def cell(name = :details, options = {}, &block)
        if @current_box
          if block_given?
            raise StandardError, 'No block accepted for cells'
            # options[:content] = @template.capture(&block)
          end
          if @cells.keys.include? name.to_s
            raise StandardError, "A cell with a given name (#{name}) has already been given."
          end
          c = Cell.new(name, options)
          @cells[name] = c
          @current_box << c
        else
          hbox do
            cell(name, options, &block)
          end
        end
      end

      def hbox(&block)
        box(&block)
      end

      def to_hash
        { version: FORMAT_VERSION, boxes: @boxes.map(&:to_hash) }
      end

      def layout(user)
        hash = nil
        if preference = user.preferences.find_by(name: preference_name)
          got = YAML.safe_load(preference.value).deep_symbolize_keys
          hash = got if got[:version] && got[:version] >= FORMAT_VERSION
        end
        hash || to_hash
      end

      # Returns ID
      # Must be set manually in app/views/layout/cell like above
      def id
        "beehive-#{@name}"
      end

      def preference_name
        "beehive.#{@name}"
      end

      def find_by_type(type)
        @cells.values.find { |c| c.type.to_s == type.to_s }
      end

      def find_by_name(name)
        @cells.values.find { |c| c.name.to_s == name.to_s }
      end

      def available_cells
        Cell.controller_types.collect do |c|
          [c.tl, c.to_s]
        end.sort do |a, b|
          a.first.ascii <=> b.first.ascii
        end
      end

      def available_cell_types
        available_cells.map(&:second)
      end

      protected

      def box(&block)
        raise StandardError, 'Cannot define box in other box' if @current_box
        old_current_box = @current_box
        if block_given?
          @current_box = Box.new
          block[self]
          @boxes << @current_box unless @current_box.empty?
        end
        @current_box = old_current_box
      end
    end
  end
end
