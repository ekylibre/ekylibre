class Progress
  class ReadOnlyError < Exception; end;

  attr_reader :name
  attr_reader :id

  PRECISION = 3
  DEFAULT_ID = 0

  def initialize(name, id: DEFAULT_ID, max: 100)
    @name = name.underscore
    @id = id
    @max = max
  end

  class << self
    def register(progress)
      @progresses ||= {}
      @progresses[progress.name] ||= {}
      @progresses[progress.name][progress.id] = progress
    end

    def unregister(name, id: DEFAULT_ID)
      return true if @progresses.nil? || @progresses[name].nil?
      @progresses[name][id] = nil
      true
    end

    def fetch(name, id: DEFAULT_ID)
      registration(name, id) || fetch!(name, id: id)
    end

    alias _new new
    def new(*args, **kwargs, &block)
      fetch(*args, **kwargs.slice(:id)) ||
        super.tap { |inst| inst.value = 0 }
    end

    def build(*args, **kwargs, &block)
      _new(*args, **kwargs, &block).tap do |inst|
        register(inst)
      end
    end

    def registered?(inst)
      registration(inst.name, inst.id).present?
    end

    def file_for(name, id)
      Ekylibre::Tenant.private_directory.join('tmp', 'imports', "#{name.downcase.underscore}-#{id}.progress")
    end

    private

    def fetch!(name, id: DEFAULT_ID)
      return nil unless File.exists?(file_for(name, id))
      build(name, id: id).tap do |prog|
        prog.read_only!
      end
    end

    def registration(name, id)
      unregister(name, id: id) unless File.exists?(file_for(name, id))
      @progresses &&
        @progresses[name.underscore] &&
        @progresses[name.underscore][id]
    end
  end

  def counting?
    File.exist?(progress_file)
  end

  def value
    return 0 unless counting?
    magnitude = 10**PRECISION
    (File.read(progress_file).to_f * magnitude).round / magnitude.to_f
  rescue
    0
  end

  def value=(value)
    no_read_only!
    self.class.register(self)
    @value = value.to_f / @max.to_f * 100
    FileUtils.mkdir_p(progress_file.dirname)
    File.write(progress_file, @value.to_s)
  end
  alias set_value value=

  def clear!
    no_read_only!
    return true unless counting?
    FileUtils.rm_rf(progress_file)
    self.class.unregister(name, id: id)
    true
  end
  alias clean! clear!

  def progress_file
    return @progress_file if defined? @progress_file
    @progress_file = self.class.file_for(name, id)
  end

  def increment!
    @value ||= value
    set_value(@value + 1)
  end

  def read_only!
    @read_only = true
  end

  def read_only?
    @read_only
  end

  private

  def no_read_only!
    raise ReadOnlyError if read_only?
  end
end
