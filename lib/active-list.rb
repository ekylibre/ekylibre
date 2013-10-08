module ActiveList

  CSV = (::CSV.const_defined?(:Reader) ? ::FasterCSV : ::CSV).freeze

  def self.version
    "5.0.0"
  end

  VERSION = self.version.freeze

  # Build and returns a short UID
  def self.new_uid
    @@last_uid ||= 0
    uid = @@last_uid.to_s(36).to_sym
    @@last_uid += 1
    return uid
  end

  autoload :Helpers,    'active-list/helpers'
  autoload :Definition, 'active-list/definition'
  autoload :Renderers,  'active-list/renderers'
  autoload :Exporters,  'active-list/exporters'
  autoload :Generator,  'active-list/generator'
  autoload :ActionPack, 'active-list/action_pack' 
end

::ActionController::Base.send(:include, ActiveList::ActionPack::ActionController)
::ActionView::Base.send(:include, ActiveList::ActionPack::ViewsHelper)
