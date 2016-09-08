module Backend::TaskboardHelper
  class Taskboard

    attr_reader :options, :columns

    def initialize(options)
      @columns = []
      @options = options[:params]
    end

    def column(options = {}, &_block)

      column = Column.new(options)

      yield column

      @columns << column
    end

    class Column
      attr_reader :column_header, :tasks, :options

      def initialize(options)
        @tasks = []
        @options = options
      end

      def header(title, actions, options = {})
        @column_header = Header.new(title, actions, options)
      end

      def task(titles, datas, actions, can_select, colors = {}, options = {})
        @tasks << Task.new(titles, datas, actions, can_select, colors, options)
      end
    end

    class Header

      attr_reader :title, :actions, :options

      def initialize(title, actions, options)

        @title = title
        @actions = actions
        @options = options
      end
    end

    class Task

      attr_reader :titles, :datas, :actions, :colors, :options

      def initialize(titles, datas, actions, can_select, colors = {}, options = {})

        @titles = titles
        @datas = datas
        @actions = actions
        @select = can_select
        @colors = colors
        @options = options[:params]
      end

      def can_select?
        @select
      end
    end
  end

  def taskboard(options = {},  &_block)

    taskboard = Taskboard.new(options)
    yield taskboard
    render partial: 'backend/shared/taskboard.html', locals: { taskboard: taskboard }
  end
end
