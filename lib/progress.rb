class Progress
  attr_reader :name
  attr_reader :id
  attr_reader :read_only

  def initialize(name, id:, reset: true, read_only: false, max: 100)
    @name = name
    @id = id
    @read_only = read_only
    @max = max
    set_value(0) if reset
  end

  class << self
    def fetch(name, id:)
      Progress.new(name, id: id, reset: false, read_only: true)
    end
  end

  def counting?
    File.exists?(progress_file)
  end

  def value
    unless counting?
      return true if @read_only
      return 0
    end
    File.read(progress_file).to_i
  end

  def set_value(value)
    return false if @read_only
    value = value/@max*100.0
    FileUtils.mkdir_p(progress_file.dirname)
    File.write(progress_file, value.to_s)
  end

  def clean!
    return true unless counting?
    File.rm_rf(progress_file)
    true
  end

  def progress_file
    return @progress_file if defined? @progress_file
    @progress_file = Ekylibre::Tenant.private_directory.join('tmp', 'imports', "#{name}-#{id}.progress")
  end
end
