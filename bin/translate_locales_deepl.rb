#!/usr/bin/env ruby
# Phase 2b: translate missing fra entries from eng using DeepL API.
#
# Usage:
#   DEEPL_API_KEY=xxx bin/translate_locales_deepl.rb [file_glob]
#
# Examples:
#   bin/translate_locales_deepl.rb                  # all fra/*.yml
#   bin/translate_locales_deepl.rb action.yml       # single file
#   DRY_RUN=true bin/translate_locales_deepl.rb     # parse and report, no API call
#
# Env vars:
#   DEEPL_API_KEY   required (unless DRY_RUN)
#   DEEPL_API_PRO   set to 'true' to use api.deepl.com (Pro), else api-free
#   DRY_RUN         set to 'true' to skip API calls and writes
#   BATCH_SIZE      texts per request (default 30)
#   RATE_DELAY      seconds between batches (default 0.4)

require 'net/http'
require 'json'
require 'uri'

LOCALES_DIR = File.expand_path('../config/locales', __dir__)
TARGET_LOCALE = 'fra'
DEEPL_SOURCE = 'EN'
DEEPL_TARGET = 'FR'

API_PRO = ENV['DEEPL_API_PRO'] == 'true'
ENDPOINT = URI(API_PRO ? 'https://api.deepl.com/v2/translate' : 'https://api-free.deepl.com/v2/translate')
DRY_RUN = ENV['DRY_RUN'].to_s.downcase == 'true'
BATCH_SIZE = (ENV['BATCH_SIZE'] || '30').to_i
RATE_DELAY = (ENV['RATE_DELAY'] || '0.4').to_f

unless DRY_RUN
  abort 'Missing DEEPL_API_KEY env var (or set DRY_RUN=true)' unless ENV['DEEPL_API_KEY']
end
API_KEY = ENV['DEEPL_API_KEY']

# Same shape as bin/decomment_locales.rb, but capture the quoted value too.
# Group 1: indent, 2: "key: ", 3: rest of the line (value possibly quoted).
PATTERN = /^(\s+)#\s([A-Za-z_][\w\-\/?=*:]*?:\s)([^|>\s].*)$/
PLACEHOLDER_RE = /(%\{[^}]+\}|\{\{[^}]+\}\}|%\{[^}]*\})/

# Extract a YAML scalar value from the rhs portion of a "key: value" line.
# Returns [raw_string, kind] where kind is :quoted, :unquoted, or :skip.
def extract_value(rhs)
  rhs = rhs.rstrip
  if rhs =~ /\A"((?:[^"\\]|\\.)*)"\z/
    [Regexp.last_match(1), :quoted]
  elsif rhs.start_with?("'") && rhs.end_with?("'")
    [rhs[1..-2], :single]
  elsif rhs.empty? || rhs.start_with?('|') || rhs.start_with?('>')
    [nil, :skip]
  else
    [rhs, :unquoted]
  end
end

def unescape_double(s)
  s.gsub(/\\(["\\nrt])/) { { '"' => '"', '\\' => '\\', 'n' => "\n", 'r' => "\r", 't' => "\t" }[Regexp.last_match(1)] }
end

def escape_double(s)
  s.gsub(/[\\"]/) { |c| "\\#{c}" }
end

def protect_placeholders(text)
  # First escape XML-significant chars so DeepL (tag_handling=xml) doesn't
  # mistake literal '<' '>' '&' in source text for tags.
  escaped = text.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
  tokens = []
  protected_text = escaped.gsub(PLACEHOLDER_RE) do |m|
    tokens << m
    "<x>#{tokens.size - 1}</x>"
  end
  [protected_text, tokens]
end

def restore_placeholders(text, tokens)
  restored = text.gsub(/<x>(\d+)<\/x>/) { tokens[Regexp.last_match(1).to_i] }
  restored.gsub('&lt;', '<').gsub('&gt;', '>').gsub('&amp;', '&')
end

def deepl_translate(texts)
  return texts.map { |_| nil } if texts.empty?

  protected_with_tokens = texts.map { |t| protect_placeholders(t) }

  http = Net::HTTP.new(ENDPOINT.host, ENDPOINT.port)
  http.use_ssl = true
  http.read_timeout = 60

  req = Net::HTTP::Post.new(ENDPOINT.request_uri)
  req['Authorization'] = "DeepL-Auth-Key #{API_KEY}"
  req['Content-Type'] = 'application/x-www-form-urlencoded'

  pairs = protected_with_tokens.map { |t, _| ['text', t] }
  pairs << ['source_lang', DEEPL_SOURCE]
  pairs << ['target_lang', DEEPL_TARGET]
  pairs << ['tag_handling', 'xml']
  pairs << ['ignore_tags', 'x']
  pairs << ['preserve_formatting', '1']
  req.body = URI.encode_www_form(pairs)

  res = nil
  3.times do |attempt|
    res = http.request(req)
    break if res.is_a?(Net::HTTPSuccess)
    if res.code == '429' || res.code == '503'
      wait = (res['Retry-After']&.to_i || (2 ** attempt * 5))
      warn "  DeepL #{res.code}, retrying in #{wait}s (attempt #{attempt + 1}/3)"
      sleep wait
      next
    end
    break
  end
  unless res.is_a?(Net::HTTPSuccess)
    raise "DeepL HTTP #{res.code}: #{res.body[0, 300]}"
  end

  body = JSON.parse(res.body)
  body.fetch('translations').each_with_index.map do |t, i|
    restore_placeholders(t['text'], protected_with_tokens[i].last)
  end
end

# Process a single file
def process_file(file)
  content = File.read(file)
  lines = content.lines
  candidates = []

  lines.each_with_index do |line, idx|
    next unless line =~ PATTERN

    indent = Regexp.last_match(1)
    key_part = Regexp.last_match(2)
    rhs = Regexp.last_match(3)
    val, kind = extract_value(rhs)
    next if kind == :skip || val.nil? || val.strip.empty?

    src = kind == :quoted ? unescape_double(val) : val
    candidates << { idx: idx, indent: indent, key: key_part, src: src, kind: kind }
  end

  return [0, 0] if candidates.empty?

  return [candidates.size, 0] if DRY_RUN

  translated_count = 0
  candidates.each_slice(BATCH_SIZE) do |batch|
    texts = batch.map { |c| c[:src] }
    translations = deepl_translate(texts)
    batch.each_with_index do |c, i|
      next if translations[i].nil? || translations[i].empty?

      out_value = if c[:kind] == :quoted
                    '"' + escape_double(translations[i]) + '"'
                  elsif c[:kind] == :single
                    "'" + translations[i].gsub("'", "''") + "'"
                  else
                    translations[i]
                  end
      lines[c[:idx]] = "#{c[:indent]}#{c[:key]}#{out_value}\n"
      translated_count += 1
    end
    sleep RATE_DELAY unless batch == candidates.each_slice(BATCH_SIZE).to_a.last
  end

  File.write(file, lines.join)
  [translated_count, candidates.size - translated_count]
end

file_filter = ARGV[0]
dir = File.join(LOCALES_DIR, TARGET_LOCALE)
abort "Locale dir #{dir} not found" unless Dir.exist?(dir)

pattern = file_filter ? File.join(dir, file_filter) : File.join(dir, '*.yml')
files = Dir.glob(pattern).sort
abort "No files match #{pattern}" if files.empty?

puts(DRY_RUN ? "Dry-run: scanning #{files.size} fra file(s)..." : "Translating #{files.size} fra file(s) via DeepL #{API_PRO ? 'Pro' : 'Free'}...")
total_translated = 0
total_failed = 0
files.each do |f|
  translated, failed = process_file(f)
  if translated.positive? || failed.positive?
    puts format('  %-45s %4d translated, %3d failed', File.basename(f), translated, failed)
  end
  total_translated += translated
  total_failed += failed
rescue => e
  warn "FAILED #{File.basename(f)}: #{e.message}"
  total_failed += 1
end

puts "\nTotal: #{total_translated} translated, #{total_failed} failed"
