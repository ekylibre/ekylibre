# Progress class permits to monitor progression of process by
# saving progress indicator value outside of an ActiveRecord transaction
# in order to permit asynchronous access to the information
class Progress
  class ReadOnlyError < RuntimeError; end

  attr_reader :name
  attr_reader :id

  PRECISION = 3
  DEFAULT_ID = 0

  def initialize(name, id: DEFAULT_ID, max: 100)
    @name = name.to_s.underscore
    @id = id
    @max = max
  end

  class << self
    def register(progress)
      name = progress.name.to_s
      @progresses ||= {}
      @progresses[name] ||= {}
      @progresses[name][progress.id] = progress
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
      Ekylibre::Tenant.private_directory.join('tmp', 'imports', "#{name.to_s.downcase.underscore}-#{id}.progress")
    end

    private

    def fetch!(name, id: DEFAULT_ID)
      return nil unless File.exist?(file_for(name, id))
      build(name, id: id).tap(&:read_only!)
    end

    def registration(name, id)
      name = name.to_s
      unregister(name, id: id) unless File.exist?(file_for(name, id))
      @progresses &&
        @progresses[name.underscore] &&
        @progresses[name.underscore][id]
    end
  end

  def counting?
    File.exist?(progress_file)
  end

  def value(percentage: true)
    return 0 unless counting?
    magnitude = 10**PRECISION
    value = File.read(progress_file).to_f
    return value.to_f / 100 * @max.to_f unless percentage && @max
    (value * magnitude).round / magnitude.to_f
  rescue
    0
  end

  def value=(value)
    return if read_only?
    self.class.register(self)
    @value = value.to_f
    percentage = value.to_f / @max.to_f * 100
    FileUtils.mkdir_p(progress_file.dirname)
    File.write(progress_file, percentage.to_s)
  end
  alias set_value value=

  def clear!
    return if read_only? && !completed?
    return true unless counting?
    FileUtils.rm_rf(progress_file)
    self.class.unregister(name, id: id)
    true
  end
  alias clean! clear!

  def completed?
    value == 100
  end

  def progress_file
    return @progress_file if defined? @progress_file
    @progress_file = self.class.file_for(name, id)
  end

  def increment!
    @value ||= (value / 100.0 * @max.to_f)
    @value += 1
    self.value = @value
  end

  def read_only!
    @read_only = true
  end

  def read_only?
    @read_only
  end
end
