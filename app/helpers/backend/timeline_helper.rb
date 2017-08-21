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

module Backend
  module TimelineHelper
    class Timeline
      attr_reader :object, :sides, :id, :others

      class Side
        attr_reader :name, :model, :label_method, :at_method

        def initialize(timeline, name, model, options = {})
          @timeline = timeline
          @name = name
          @model = model
          @label_method = options[:label_method]
          @at_method = options[:at] || options[:at_method] || :created_at
          @label = options[:label]
          @new = !options[:new].is_a?(FalseClass)
          @params = options[:params] || {}
          @params.update(options[:new]) if options[:new].is_a?(Hash)
          @authorization_proc = options[:if]
        end

        def human_name
          @label
        end

        def model_name
          @model_name ||= model.name.underscore.to_sym
        end

        def controller_name
          @controller_name ||= model.name.tableize.to_s
        end

        def new_url?
          @new
        end

        def authorized?
          @authorization_proc.nil? || @authorization_proc.call(object)
        end

        def object
          @timeline.object
        end

        def count
          @count ||= records.count
        end

        def steps
          unless @steps
            @steps = records.collect do |record|
              SideStep.new(self, record.send(at_method), record)
            end
            @timeline.others.each do |other|
              other.send(@name).collect do |record|
                unless @steps.detect { |s| s.record == record }
                  @steps << SideStep.new(self, record.send(at_method), record)
                end
              end
            end
          end
          @steps
        end

        def records
          @records ||= @timeline.object.send(@name)
        end

        attr_reader :params
      end

      class Step
        attr_reader :at, :name

        def initialize(at, name)
          @at = at
          @name = name
        end

        def <=>(other)
          at <=> other.at
        end
      end

      class MarkerStep < Step
        attr_reader :key
        def initialize(at, key, name = nil)
          @key = key
          name ||= key.tl
          super(at, name)
        end
      end

      class SideStep < Step
        attr_reader :side, :record

        def initialize(side, at, record)
          @side = side
          @record = record
          at ||= record.created_at
          super(at, @record.send(side.label_method))
        end

        def author
          @record.creator
        end

        def inspect
          "<Step #{@side.name} #{@at ? @at.l : @at.inspect} #{@record.id}>"
        end
      end

      def initialize(object, options = {})
        @object = object
        @model = @object.class
        @sides = []
        @id = options[:id]
        @others = options[:others] || []
      end

      def steps
        list = []
        @sides.each do |side|
          list += side.steps if side.authorized?
        end
        now = Time.zone.now
        list << MarkerStep.new(now, :now) if list.detect { |s| s.at > now }
        count = 1
        ago = now - 1.year
        while list.detect { |s| s.at < ago }
          if list.detect { |s| (ago - 1.year) < s.at && s.at < ago }
            step = MarkerStep.new(ago, :past, 'datetime.distance_in_words.over_x_years'.t(count: count))
            list << step
          end
          count += 1
          ago = now - count.year
        end
        list.compact.sort.reverse
      end

      def side(name, options = {})
        unless reflection = @model.reflect_on_association(name)
          raise ArgumentError, "Invalid reflection #{name.inspect} for #{@model.name}"
        end
        klass = reflection.class_name.constantize
        available_methods = klass.columns_hash.keys.map(&:to_sym)
        options[:label_method] ||= %i[label name number coordinates id].detect { |m| available_methods.include?(m) } || :id
        options[:params] ||= {}
        options[:params][reflection.foreign_key.to_sym] ||= @object.id
        options[:params]["#{reflection.options[:as]}_type".to_sym] ||= @model.name if reflection.options[:as]
        options[:label] ||= @model.human_attribute_name(name)
        @sides << Side.new(self, name.to_sym, klass, options)
      end

      def method_missing(method_name, *args)
        side(method_name.to_sym, *args)
      end
    end

    def timeline(object, options = {}, &_block)
      if object
        line = Timeline.new(object, options)
        yield line
        render partial: 'backend/shared/timeline', locals: { timeline: line }
      end
    end
  end
end
