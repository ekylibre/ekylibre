class Progress
  attr_reader :name
  attr_reader :id

  def initialize(name, id:, reset: true)
    @name = name
    @id = id
    set_value(0) if reset
  end

  class << self
    def fetch(name, id:)
      Progress.new(name, id: id, reset: false)
    end
  end

  def counting?
    File.exists?(progress_file)
  end

  def value
    return 0 unless counting?
    File.read(progress_file).to_i
  end

  def set_value(value)
    FileUtils.mkdir_p(progress_file.dirname)
    File.write(progress_file, value.to_s)
  end

  def clean
    return true unless counting?
    File.rm_rf(progress_file)
    true
  end

  def progress_file
    return @progress_file if defined? @progress_file
    @progress_file = Ekylibre::Tenant.private_directory.join('tmp', 'imports', "#{name}-#{id}.progress")
  end
end
