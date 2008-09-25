namespace :eky do

  task :migration => :environment do
    class Default < ActiveRecord::Migration
      def self.up
      	company = Company.create!(:name=>'The False Company', :code=>'TFC')
#      	u = User.new(:name=>'admin', :first_name=>'Toto', :last_name=>'ADMIN', :password=>'4dm|n', :password_confirmation=>'4dm|n', :company_id=>company.id)
#        u.role_id = company.admin_role.id
#        u.save
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
