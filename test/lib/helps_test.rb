require 'test_helper'

class HelpsTest < ActiveSupport::TestCase
  # Checks the validity of references files for models
  def test_help_files
    for file in Dir[Rails.root.join('config', 'locales', '*', 'help', '*.txt')].sort
      File.open(file, 'rb:UTF-8') do |f|
        title = f.read[/^======\s*(.*)\s*======$/, 1].to_s.strip
        assert_not_equal 0, title.size, "A title must be given for help file #{file}"
      end
    end
  end
end
