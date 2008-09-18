namespace :eky do

  task :migration => :environment do
    class Default < ActiveRecord::Migration
      def self.up
      	Language.create!(:name=>'English', :native_name=>'English', :iso2=>'en', :iso3=>'eng')
      	language = Language.create!(:name=>'French', :native_name=>'Français', :iso2=>'fr', :iso3=>'fra')
      	Language.create!(:name=>'Spanish', :native_name=>'Español', :iso2=>'es', :iso3=>'spa')
      	company = Company.create!(:name=>'The False Company', :code=>'TFC')
      	role = Role.create!(:name=>'Default', :default=>true, :company_id=>company.id)
      	u = User.new(:name=>'admin', :first_name=>'Toto', :last_name=>'ADMIN', :password=>'4dm|n', :password_confirmation=>'4dm|n', :company_id=>company.id, :language_id=>language.id)
        u.role_id = role.id
        u.admin = true
        u.save
      	f = File.open("#{RAILS_ROOT}/lib/template.xml",'r')
      	Template.create!(:name=>'test',:company_id=>company.id, :content=>f.read)
      	f.close
      end
       
      def self.down
      end
    end
  end
	
  desc "Load default data Group/User"
  task :up => :migration do
    Default.up
  end
  
end
