module ActiveExchanger
  class Supervisor
    attr_reader :color, :cursor, :errors

    def initialize(mode = :normal, &block)
      if block_given?
        raise 'Invalid arity must be 1..2' unless (1..2).cover?(block.arity)
        @block = block
      end
      @mode = mode
      @max = ENV['max'].to_i
      @count = nil
      @color = :green
      @cursor = 0
      @errors = []
    end

    def count=(value)
      raise 'Need a positive value' unless value >= 0
      @count = value
      @count = @max if @max > 0 && @count > @max
    end

    def check_point(new_cursor = nil)
      raise 'You need to set count before calling check_point' unless @count
      if new_cursor
        @cursor = new_cursor
      else
        @cursor += 1
      end
      if @block
        value = (100.0 * (@cursor.to_f / @count.to_f))
        if value != @last_value
          if @block.arity == 1
            @block.call(value)
          elsif @block.arity == 2
            @block.call(value, @cursor)
          end
          @last_value = value
        end
      end
    end

    def reset!(value = nil, color = :green)
      self.count = value if value
      @cursor = 0
      @color = color
    end

    def verbose?
      ENV['VERBOSE'].to_i > 0
    end

    def debug(msg)
      print("\n" + 'DEBUG'.white + ': ' + msg) if verbose?
      Rails.logger.debug(msg)
    end

    def info(msg)
      print("\n" + msg.gsub(/^/, 'INFO'.green + ': ')) if verbose?
      Rails.logger.info(msg)
    end

    def warn(msg)
      print("\n" + 'WARNING'.yellow + ': ' + msg) if verbose?
      Rails.logger.error(msg)
    end

    def error(msg)
      @errors << msg

      print("\n" + 'ERROR'.red + ': ' + msg) if verbose?
      Rails.logger.error(msg)
    end

    def fatal(msg)
      print("\n" + 'FATAL'.red + ': ' + msg) if verbose?
      Rails.logger.fatal(msg)
    end

    def tmp_dir(*subdirs)
      number = (1000 * Time.zone.now.to_f).to_i.to_s(36) + Array.new(3) { rand(1_679_616) }.sum.to_s(36)
      dir = Rails.root.join('tmp', 'exchangers', number, *subdirs)
      FileUtils.mkdir_p(dir)
      dir
    end
  end
end
