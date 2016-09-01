module Backend::TaskboardHelper
  class Taskboard

    attr_reader :options, :headers_options, :taskboard_headers, :taskboard_lines

    def initialize(options)
      @options = options[:params]
      @taskboard_headers = []
      @taskboard_lines = []
    end

    def headers(options = {}, &_block)
      headers = Headers.new(options)
      yield headers

      @taskboard_headers = headers.headers_list
      @headers_options = headers.options
    end

    def lines(options = {}, &_block)
      line = Line.new(options)
      yield line

      @taskboard_lines << line
    end

    class Headers

      attr_reader :headers_list, :options

      def initialize(options)

        @headers_list = []
        @options = options
      end

      def content(title, actions, options = {})
        @headers_list << Header.new(title, actions, options)
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

    class Line
      attr_reader :blocks, :options

      def initialize(options)
        @blocks = []
        @options = options
      end

      def block(options = {}, &_block)
        block = Block.new(options)
        yield block unless _block.nil?

        @blocks << block
      end
    end

    class Block

      attr_reader :tasks, :options

      def initialize(options)

        @tasks = []
        @options = options
      end

      def task(titles, datas, actions, can_select, colors = {}, options = {})
        @tasks << Task.new(titles, datas, actions, can_select, colors, options)
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
