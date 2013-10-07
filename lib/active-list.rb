module ActiveList

  CSV = (::CSV.const_defined?(:Reader) ? ::FasterCSV : ::CSV).freeze

  def self.version
    "4.2.3"
  end

  VERSION = self.version.freeze

  def self.assets_path
    File.join(File.dirname(__FILE__), "assets", "images")
  end

  # Build and returns a short UID
  def self.new_uid
    @@last_uid ||= 0
    uid = @@last_uid.to_s(36).to_sym
    @@last_uid += 1
    return uid
  end

end

require "active-list/helpers"
require "active-list/definition"
require "active-list/generator"
require "active-list/action_pack"


::ActionController::Base.send(:include, ActiveList::ActionController)
::ActionView::Base.send(:include, ActiveList::ViewsHelper)
