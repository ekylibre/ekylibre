module Ekylibre::FirstRun::Faker
  class Base
    def self.run(options = {})
      new(options).run
    end

    def initialize(options = {})
      @max = options[:max] || 0
    end

    def files
      Pathname.new(__FILE__).dirname.join('files')
    end

    def path(*args)
      files.join(*args)
    end

    def count(name, options = {}, &_block)
      STDOUT.sync = true
      f = Ekylibre::FirstRun::Counter.new(@max) do |_count, _increment|
        print '.'
      end
      start = Time.now
      label_size = options[:label_size] || 21
      label = name.to_s.humanize.rjust(label_size)
      label = Ekylibre::FirstRun::Base.ellipse(label, label_size)
      print "[#{'FAKE'.magenta}] #{label.blue}: "
      begin
        yield(f)
        print ' ' * (@max - f.count) if 0 < @max and @max > f.count
        print '  '
      rescue Ekylibre::FirstRun::Counter::CountExceeded => e
        print '! '
      end
      puts "#{(Time.now - start).round(2).to_s.rjust(6)}s"
    end
  end
end
