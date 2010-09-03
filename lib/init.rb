require File.dirname(__FILE__) + '/acts_as_accountable'
require File.dirname(__FILE__) + '/safe_string'
require File.dirname(__FILE__) + '/hash_string'
require File.dirname(__FILE__) + '/i18n'
require File.dirname(__FILE__) + '/models'
# require File.dirname(__FILE__) + '/spreet'
require File.dirname(__FILE__) + '/active_record'
require File.dirname(__FILE__) + '/adapters'
require File.dirname(__FILE__) + '/fix_sqlserver'


module Ekylibre
  @@version = nil
  
  def self.version
    return @@version unless @@version.nil?
    File.open(Rails.root.join("VERSION")) {|f| @@version = f.read.split(',')[1]}
    return @@version
  end  
end
