module Backend::TaskboardHelper
  class Taskboard

    attr_reader :options, :headers_options, :taskboard_headers, :taskboard_lines

    def initialize(_options)
      @options = _options[:params]
      @taskboard_headers = []
      @taskboard_lines = []
    end

    def headers(_options = {}, &_block)
      headers = Headers.new(_options)
      yield headers

      @taskboard_headers = headers.headers_list
      @headers_options = headers.options
    end

    def lines(_options = {}, &_block)
      line = Line.new(_options)
      yield line

      @taskboard_lines << line
    end

    class Headers

      attr_reader :headers_list, :options

      def initialize(_options)

        @headers_list = []
        @options = _options
      end

      def content(title, actions, options = {})
        @headers_list << Header.new(title, actions, options)
      end
    end

    class Header

      attr_reader :title, :actions, :options

      def initialize(_title, _actions, _options)

        @title = _title
        @actions = _actions
        @options = _options
      end
    end

    class Line
      attr_reader :blocks, :options

      def initialize(_options)
        @blocks = []
        @options = _options
      end

      def block(_options = {}, &_block)
        block = Block.new(_options)
        yield block unless _block.nil?

        @blocks << block
      end
    end

    class Block

      attr_reader :tasks, :options

      def initialize(_options)

        @tasks = []
        @options = _options
      end

      def task(_titles, _datas, _actions, _select, _colors = {}, _options = {})
        @tasks << Task.new(_titles, _datas, _actions, _select, _colors, _options)
      end
    end

    class Task

      attr_reader :titles, :datas, :actions, :colors, :options

      def initialize(_titles, _datas, _actions, _select, _colors = {}, _options = {})

        @titles = _titles
        @datas = _datas
        @actions = _actions
        @select = _select
        @colors = _colors
        @options = _options[:params]
      end

      def can_select?
        @select
      end
    end
  end

  def taskboard(_options = {},  &_block)

    taskboard = Taskboard.new(_options)
    yield taskboard
    render partial: 'backend/shared/taskboard.html', locals: { taskboard: taskboard }
  end
end
