module ActiveExchanger
  class Error < ::StandardError
  end

  class NotSupportedFormatError < Error
  end

  class NotWellFormedFileError < Error
  end

  class IncompatibleDataError < Error
  end

  class InvalidDataError < Error
  end
end

require 'active_exchanger/base'
require 'active_exchanger/supervisor'

if Rails.env.development?
  Dir.glob(Rails.root.join('app', 'exchangers', '**', '*.rb')).each do |path|
    require_dependency path
  end
end
