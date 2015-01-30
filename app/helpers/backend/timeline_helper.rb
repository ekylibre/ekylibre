# encoding: utf-8
# ##### BEGIN LICENSE BLOCK #####
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2009-2015 Brice Texier
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
# ##### END LICENSE BLOCK #####

# encoding: utf-8

module Backend::TimelineHelper

  class Timeline

    class Side
      attr_reader :name, :model, :label_method

      def initialize(name, model, label_method)
        @name = name
        @model = model
        @label_method = label_method
      end

      def at_method
        :created_at
      end

      def model_name
        @model_name ||= model.name.underscore.to_sym
      end

      def controller_name
        @controller_name ||= model.name.tableize.to_s
      end
    end

    class Step
      attr_reader :side, :at, :record

      def initialize(side, at, record)
        @side = side
        @at = at
        @record = record
      end

      def <=>(other)
        @at <=> other.at
      end

      def name
        @record.send(side.label_method)
      end

      def author
        @record.creator
      end

      def inspect
        "<Step #{@side.name} #{@at.l} #{@record.id}>"
      end

    end

    def initialize(object)
      @object = object
      @model = @object.class
      @sides = []
    end

    def steps
      list = []
      @sides.each do |side|
        list += @object.send(side.name).collect do |record|
          Step.new(side, record.send(side.at_method), record)
        end
      end
      return list.compact.sort.reverse
    end

    def side(name)
      unless reflection = @model.reflections[name]
        raise ArgumentError, "Invalid reflection #{name.inspect} for #{@model.name}"
      end
      klass = reflection.class_name.constantize
      available_methods = klass.columns_hash.keys.map(&:to_sym)
      label_method = [:label, :name, :number, :coordinates, :id].detect{|m| available_methods.include?(m) } || :id
      @sides << Side.new(name.to_sym, klass, label_method)
    end

    def method_missing(method_name, *args)
      side(method_name.to_sym, *args)
    end

  end


  def timeline(object, &block)
    if object
      line = Timeline.new(object)
      yield line
      render partial: "backend/timeline", locals: {timeline: line}
    end
  end

end
