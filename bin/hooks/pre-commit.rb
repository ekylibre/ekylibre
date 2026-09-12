#!/usr/bin/env ruby

# Place in your project .git/hooks/pre-commit
# Heavily inspired by https://raw.githubusercontent.com/balabhadra/githooks/master/pre-commit, so thank you to him

############# CONFIGURATION

# The two sections of regular expressions below ("forbidden" and "warning")
# will trigger a commit failure, *if* they are found on an added or edited line.

# "Forbidden" regular expressions
FORBIDDEN_STRINGS = [
  /TMP_DEBUG/, # My TextExpander macros for embedding debug code always include this for easy scanning.
  />>>>>>/,    # Git conflict markers
  /<<<<<</,    # ''
  /binding\.pry/,        # pry debugging code
  /binding\.remote_pry/, # ''
  /save_and_open_page/,  # Launchy debugging code
  /debugger/,      # Ruby < 2.0 debugging code
  /byebug/,        # Ruby >= 2.0 debugging code
  /logger\.debug/  # I almost never want to commit a (Ruby) call to logger.debug.  error, message, etc., but not debug.
]

# Motifs qui ne visent que du code applicatif : dans le Gemfile, ce sont des
# noms de gems légitimes — `pry-byebug` est une dépendance de développement de
# longue date — et le motif y donnait un faux positif à chaque montée de
# version. Ce fichier-ci est exempté pour la même raison : il *contient* les
# motifs.
FORBIDDEN_IN_CODE_ONLY = FORBIDDEN_STRINGS.select { |re| %w[debugger byebug].any? { |w| re.source.include?(w) } }.freeze
PATHS_EXEMPT_FROM_CODE_PATTERNS = [
  %r{\AGemfile(\.lock|\.local|\.prod)?\z},
  %r{\Abin/hooks/pre-commit\.rb\z}
].freeze

# Warning signs that someone is committing a private key
PRIVATE_KEY_INDICATORS = [
  /PRIVATE KEY/,
  /ssh-rsa/
]

#Warning signs that someone is committing files with secrets.
SECRET_INDICATORS = [
  /application\.yml/
]

############# END OF CONFIGURATION

# Check for "forbidden" and "warning" strings

# Loop over ALL errors and warnings and return ALL problems.
# I want to report on *all* problems that exist in the commit before aborting,
# so that anyone calling --no-verify has been informed of all problems first.
error_found = false

full_diff = `git diff --cached --`

full_diff.scan(%r{^\+\+\+ b/(.+)\n@@.*\n([\s\S]*?)(?:^diff|\z)}).each do |file, diff|
  changed_code_for_file = diff.split("\n").select { |x| x.start_with?("+") }.join("\n")
  changed_lines_for_file = diff.split("\n").select { |x| x.start_with?("+") }
  dir = File.dirname(file)

  # Scan for "forbidden" calls
  FORBIDDEN_STRINGS.each do |re|
    # `byebug` et `debugger` désignent ici des appels de débogage oubliés. Dans
    # le Gemfile et son verrou, ce sont des noms de gems légitimes —
    # `pry-byebug` est une dépendance de développement déclarée de longue date —
    # et le motif y donnait un faux positif à chaque montée de version.
    next if FORBIDDEN_IN_CODE_ONLY.include?(re) && PATHS_EXEMPT_FROM_CODE_PATTERNS.any? { |p| file.match?(p) }

    if changed_code_for_file.match(re)
      puts %{Error: git pre-commit hook forbids committing "#{$1 || $&}" to #{file}\n--------------}
      error_found = true
    end
  end

  # Scan for private key indicators
  PRIVATE_KEY_INDICATORS.each do |re|
    if changed_code_for_file.match(re)
      puts %{Error: git pre-commit hook detected a probable private key commit: "#{$1 || $&}" to #{file}\n--------------}
      error_found = true
    end
  end

  # Scan for secret file indicators
  SECRET_INDICATORS.each do |re|
    if file.match(re)
      puts %{Error: git pre-commit hook detected a probable secret file commit: "#{$1 || $&}" to #{file}\n--------------}
      error_found = true
    end
  end
end

#If trying to add an empty file that is prohibited
full_diff.scan(%r{^diff --git a/(.+) b/.*\nnew file mode}).each do |file|
  # Scan for secret file indicators.
  SECRET_INDICATORS.each do |re|
    if file[0].match(re)
      puts %{Error: git pre-commit hook detected a probable secret file commit: "#{$1 || $&}" to #{file}\n--------------}
      error_found = true
    end
  end
end

FILE_SIZE_LIMIT = 99 #MB
command = "git ls-files -t `find . -type f -size +#{FILE_SIZE_LIMIT}M |xargs`"
too_large_files = `#{command}`.split(/\n+/)

if too_large_files.any?
  too_large_files.each do |file|
    file_path = file.split(' ').last
    puts %{Error: git pre-commit hook detected file with size superior to #{FILE_SIZE_LIMIT}MB: "#{file_path}\n--------------}
    error_found = true
  end
end

# Finally, report errors
if error_found
  puts "To commit anyway, use --no-verify"
  exit 1
end