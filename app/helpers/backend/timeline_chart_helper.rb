module Backend
  module TimelineChartHelper
    class TimelineChart
      attr_reader :id

      def initialize(id, min_date, max_date)
        @id = id
        @min_date = min_date
        @max_date = max_date

        @groups = []
      end

      def group(label, &_block)
        group = Group.new(label)
        yield group

        @groups << group
      end

      def datas
        datas = Hash.new { |h, k| h[k] = [] }
        datas[:chart_id] = @id
        datas[:min_date] = @min_date
        datas[:max_date] = @max_date

        @groups.each do |group|
          timeline_datas = Hash.new { |h, k| h[k] = [] }
          timeline_datas[:label] = group.label
          timeline_datas[:data] = [] unless group.items.any?

          group.items.each do |item|
            timeline_datas[:data] << item.get_datas
          end

          datas[:datas] << timeline_datas
        end

        datas
      end

      def events
        events = []

        @groups.each do |group|
          group.items.each do |item|
            events << item.get_js_datas unless item.get_js_datas.nil?
          end
        end

        events
      end

      class Group
        attr_reader :label, :items

        def initialize(label)
          @label = label
          @items = []
        end

        def interval(label, started_date, stopped_date, options = {}, js_options = {})
          @items << Interval.new(label, started_date, stopped_date, options, js_options)
        end

        def point(label, targetted_at, options = {}, js_options = {})
          @items << Point.new(label, targetted_at, options, js_options)
        end

        def icon(label, targetted_at, icon, font_size, options = {}, js_options = {})
          @items << Icon.new(label, targetted_at, icon, font_size, options, js_options)
        end
      end

      class Item
        INTERVAL = 'TimelineChart.TYPE.INTERVAL'.freeze
        POINT = 'TimelineChart.TYPE.POINT'.freeze
        ICON = 'TimelineChart.TYPE.ICON'.freeze

        def initialize(label, type, options = {}, js_options = {})
          @label = label
          @type = type
          @id = options[:id]
          @custom_class = options[:custom_class]
          @js_options = js_options
        end

        def get_datas
          item_datas = {}

          item_datas[:label] = @label
          item_datas[:type] = @type
          item_datas[:id] = @id unless @id.nil?
          item_datas[:customClass] = @custom_class unless @custom_class.nil?
          custom_datas(item_datas)

          item_datas
        end

        def get_js_datas
          js_datas = {}

          @js_options.each_pair do |event_name, event_content|
            js_datas[:element_id] = @id
            js_datas[event_name] = event_content
          end

          js_datas
        end

        def custom_datas
        end
      end

      class Interval < Item
        def initialize(label, started_date, stopped_date, options = {}, js_options = {})
          @started_date = started_date
          @stopped_date = stopped_date

          super(label, INTERVAL, options, js_options)
        end

        def custom_datas(item_datas)
          item_datas[:from] = @started_date
          item_datas[:to] = @stopped_date
        end
      end

      class Point < Item
        def initialize(label, targetted_at, options = {}, js_options = {})
          @targetted_at = targetted_at

          super(label, POINT, options, js_options)
        end

        def custom_datas(item_datas)
          item_datas[:at] = @targetted_at
        end
      end

      class Icon < Item
        def initialize(label, targetted_at, icon, font_size, options = {}, js_options = {})
          @targetted_at = targetted_at
          @icon = icon
          @font_size = font_size

          super(label, ICON, options, js_options)
        end

        def custom_datas(item_datas)
          item_datas[:at] = @targetted_at
          item_datas[:icon] = @icon
          item_datas[:font_size] = @font_size
        end
      end
    end

    def timeline_chart(id, min_date, max_date, &_block)
      unless id.nil? && min_date.nil? && max_date.nil?
        timeline_chart = TimelineChart.new(id, min_date, max_date)
        yield timeline_chart
        render partial: 'backend/shared/timeline_chart.html', locals: { timeline_chart: timeline_chart }
      end
    end
  end
end
