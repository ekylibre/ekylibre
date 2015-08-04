require 'test_helper'

class Backend::HelpsHelperTest < ActionView::TestCase
  for file in Dir.glob(Rails.root.join('config', 'locales', '*', 'help', '**', '*.txt'))
    File.open(file, 'rb:UTF-8') do |f|
      source = f.read
      test "wikization of '#{file.gsub(Rails.root.to_s, '.')}'" do
        wikize(source, url: { controller: :helps, action: :show }, no_link: true)
      end
    end
  end
end
