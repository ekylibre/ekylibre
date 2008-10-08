# == Schema Information
# Schema version: 20080819191919
#
# Table name: companies
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  code         :string(8)     not null
#  siren        :string(9)     
#  born_on      :date          
#  locked       :boolean       not null
#  deleted      :boolean       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class Company < ActiveRecord::Base
  has_many :users

  PRIVATE='private/'
  REPORTS='reports/'
  
  def before_validation
    self.code = name[0..7].simpleize if code.blank?
    self.code = rand.to_s[2..100].to_i.to_s(36)[0..7] if code.blank?
    self.code.upper!
    while Company.count(:conditions=>["code=? AND id!=?",self.code, self.id])>0 do
      self.code.succ!
    end
    self.siren = '123456789' if self.siren.blank?
  end

  def after_create
    role = Role.create!(:name=>lc(:administrator), :company_id=>self.id)
    role.can_do :all
    role = Role.create!(:name=>lc(:public), :company_id=>self.id)
    self.parameter('general.language').value=Language.find_by_iso2('fr')
    self.load_template("#{RAILS_ROOT}/lib/template.xml")
    self.departments.create(:name=>lc(:default_department_name))
    self.establishments.create(:name=>lc(:default_establishment_name), :nic=>"00000")
  end

  # this function saves the pdf document genererated by the function render_report in the table reports in the database
  def register_report(template_md5,key,binary,title)
    Dir.mkdir(PRIVATE+REPORTS) unless File.directory? PRIVATE+REPORTS 
    
    binary_digest=Digest::SHA256.hexdigest(binary)
    
    unless Report.exists?(["template_md5 = ? AND key = ?", template_md5, key])
      report=Report.create!(:key=>key,:template_md5=>template_md5,:sha256=>binary_digest, :original_name=>title, :printed_at=>Time.now,:company_id=>self.id)
      report.filename=PRIVATE+REPORTS+report.id.to_s
      report.save!
      
    end
    
  end


  def parameter(name)
    parameter = Parameter.find_by_name_and_company_id(name,self.id)
    parameter = Parameter.new(:name=>name, :nature=>:u, :company_id=>self.id)
    parameter
  end

  def load_template(filename)
    f = File.open(filename,'rb')
    Template.create!(:name=>filename.simpleize,:company_id=>self.id, :content=>f.read)
    f.close
  end

  def admin_role
    self.roles.find(:first, :conditions=>"actions=' all '")
  end

end
