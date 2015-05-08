module ActiveExchanger

  class Error < ::StandardError
  end

  class NotSupportedFormatError < Error
  end

  class NotWellFormedFileError < Error
  end

  class IncompatibleDataError < Error
  end

  autoload :Base,       'active_exchanger/base'
  autoload :Supervisor, 'active_exchanger/supervisor'

end

Dir.glob(Rails.root.join("app", "exchangers", "**", "*.rb")).each do |path|
  require path
end
