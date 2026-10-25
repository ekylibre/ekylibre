#!/usr/bin/env ruby
# Phase 2a: decomment auto-humanized missing entries in <locale>/*.yml
#
# Usage: bin/decomment_locales.rb [locale] [file]
#   Default locale: eng
#   Default scope: all *.yml files for that locale
#
# Only decomments single-line entries of the form `# key: "value"`. Multi-line
# block-scalar entries (`# key: |` followed by indented lines) are left untouched
# and reported as skipped — they need targeted handling.

require 'optparse'

LOCALES_DIR = File.expand_path('../config/locales', __dir__)

# Match: indent + "# " + valid YAML key + ": " + scalar value.
# Key accepts letters, digits, underscore, dash, slash, `::` (for STI class
# names like `VariantCategories::AnimalCategory`) and common suffixes
# `?` `=` `*`. The non-greedy `*?` stops at the first `: ` separator.
PATTERN = /^(\s+)#\s([A-Za-z_][\w\-\/?=*:]*?:\s)([^|>\s].*)$/

def decomment_file(file)
  content = File.read(file)
  decommented = 0
  new_content = content.gsub(PATTERN) do
    decommented += 1
    "#{Regexp.last_match(1)}#{Regexp.last_match(2)}#{Regexp.last_match(3)}"
  end
  skipped = content.scan(/^\s+#\s\S[^:]*?:\s*([|>].*)?$/).count - decommented
  File.write(file, new_content) if decommented.positive?
  [decommented, skipped]
end

locale = ARGV[0] || 'eng'
file_filter = ARGV[1]

dir = File.join(LOCALES_DIR, locale)
abort "Locale dir #{dir} not found" unless Dir.exist?(dir)

pattern = file_filter ? File.join(dir, file_filter) : File.join(dir, '*.yml')
files = Dir.glob(pattern).sort
abort "No files match #{pattern}" if files.empty?

total_decommented = 0
total_skipped = 0
files.each do |f|
  decommented, skipped = decomment_file(f)
  next if decommented.zero? && skipped.zero?

  puts format('  %-50s %4d decommented, %3d skipped (block)',
              File.basename(f), decommented, [skipped, 0].max)
  total_decommented += decommented
  total_skipped += [skipped, 0].max
end

puts "\nTotal: #{total_decommented} decommented, #{total_skipped} block entries skipped across #{files.size} file(s) in #{locale}/"
