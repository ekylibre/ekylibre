require 'minitest'

# This file is here so that Minitest is able to find and activate the plugin
module Minitest
  class << self
    def plugin_ekylibre_init(options)
      Ekylibre::Testing::Minitest::ProfilePlugin.register(options)
    end

    def plugin_ekylibre_options(opts, options)
      Ekylibre::Testing::Minitest::ProfilePlugin.parse_options(opts, options)
    end
  end
end