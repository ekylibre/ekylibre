# Version: 5.0.0
module ActiveList

  CSV = Ekylibre::CSV

  # Build and returns a short UID
  def self.new_uid
    @@last_uid ||= 0
    uid = @@last_uid.to_s(36).to_sym
    @@last_uid += 1
    return uid
  end

  autoload :Helpers,    'active_list/helpers'
  autoload :Definition, 'active_list/definition'
  autoload :Renderers,  'active_list/renderers'
  autoload :Exporters,  'active_list/exporters'
  autoload :Generator,  'active_list/generator'
  autoload :ActionPack, 'active_list/action_pack'
end
