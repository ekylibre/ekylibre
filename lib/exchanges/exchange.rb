module Exchanges

  class Exchange

    def initialize(&block)
      if block_given?
        unless (1..2).include?(block.arity)
          raise "Invalid arity must be 1..2"
        end
        @block = block
      end
      @max = ENV["max"].to_i
      @count = nil
      @cursor = 0
    end

    def count=(value)
      raise "Need a positive value" unless value > 0
      @count = value
      @count = @max if @max > 0 and @count > @max
    end

    def check_point(new_cursor = nil)
      unless @count
        raise "You need to set count before calling check_point"
      end
      if new_cursor
        @cursor = new_cursor
      else
        @cursor += 1
      end
      if @block
        value = (100.0*(@cursor.to_f / @count.to_f)).to_i
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

    def reset!
      @cursor = 0
    end

    def verbose?
      ENV["VERBOSE"].to_i > 0
    end

    def debug(msg)
      puts("DEBUG".white + ": " + msg) if verbose?
      Rails.logger.debug(msg)
    end

    def info(msg)
      puts("INFO".green + ": " + msg) if verbose?
      Rails.logger.info(msg)
    end

    def warn(msg)
      puts("WARNING".yellow + ": " + msg) if verbose?
      Rails.logger.error(msg)
    end

    def error(msg)
      puts("ERROR".red + ": " + msg) if verbose?
      Rails.logger.error(msg)
    end

    def fatal(msg)
      puts("FATAL".red + ": " + msg) if verbose?
      Rails.logger.fatal(msg)
    end

    def tmp_dir(*subdirs)
      number = (1000 * Time.now.to_f).to_i.to_s(36) + 3.times.collect{ rand(1679616) }.sum.to_s(36)
      dir = Rails.root.join("tmp", "exchanges", number, *subdirs)
      FileUtils.mkdir_p(dir)
      return dir
    end

  end

end
