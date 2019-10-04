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

# Warning signs that someone is committing a private key
PRIVATE_KEY_INDICATORS = [
  /PRIVATE KEY/,
  /ssh-rsa/
]

#Warning signs that someone is committing files with secrets.
SECRET_INDICATORS = [
  /database\.yml/,
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

# Finally, report errors
if error_found
  puts "To commit anyway, use --no-verify"
  exit 1
end