require 'test_helper'

module Backend
  class HelpsHelperTest < ActionView::TestCase
    Dir.glob(Rails.root.join('config', 'locales', '*', 'help', '**', '*.txt')).each do |file|
      File.open(file, 'rb:UTF-8') do |f|
        source = f.read
        test "wikization of '#{file.gsub(Rails.root.to_s, '.')}'" do
          wikize(source, url: { controller: :helps, action: :show }, no_link: true)
        end
      end
    end
  end
end
