# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

Rack::Utils.multipart_total_part_limit = 0

require ::File.expand_path('config/environment', __dir__)
run Rails.application
