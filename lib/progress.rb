class Progress
  attr_reader :name
  attr_reader :id

  PRECISION = 3

  def initialize(name, id:, max: 100)
    @name = name.underscore
    @id = id
    @max = max
    set_value(0)
    self.class.register(self)
  end

  class << self
    def register(progress)
      @progresses ||= Hash.new
      @progresses[progress.name] ||= {}
      @progresses[progress.name][progress.id] = progress
    end

    def unregister(progress)
      return true if @progresses.nil?
      @progresses[progress.name][progress.id] = nil
      true
    end

    def fetch(name, id:)
      @progresses[name.underscore][id]
    end
  end

  def counting?
    File.exists?(progress_file)
  end

  def value
    return 0 unless counting?
    magnitude = 10**PRECISION
    (File.read(progress_file).to_f * magnitude).round / magnitude.to_f
  rescue
    0
  end

  def set_value(value)
    self.class.register(self)
    @value = value.to_f/@max.to_f*100
    FileUtils.mkdir_p(progress_file.dirname)
    File.write(progress_file, @value.to_s)
  end

  def clear!
    return true unless counting?
    FileUtils.rm_rf(progress_file)
    self.class.unregister(self)
    true
  end
  alias clean! clear!

  def progress_file
    return @progress_file if defined? @progress_file
    @progress_file = Ekylibre::Tenant.private_directory.join('tmp', 'imports', "#{name}-#{id}.progress")
  end

  def increment!
    @value ||= value
    set_value(@value + 1)
  end
end
