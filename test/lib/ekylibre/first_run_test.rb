# encoding: UTF-8
require 'test_helper'

class Ekylibre::FirstRunTest < ActiveSupport::TestCase

  test "launch of default first run" do
    Ekylibre::FirstRun.launch(name: "test_default", path: Rails.root.join("db", "first_runs", "default"), verbose: false)
  end

  # test "launch of test first run" do
  #   Ekylibre::FirstRun.launch(path: Rails.root.join("test", "fixtures", "files", "first_run"), name: :sekindov)
  # end

end
