# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2010 Brice Texier, Thibaud Mérigon
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
# 
# == Table: companies
#
#  born_on          :date             
#  code             :string(16)       not null
#  created_at       :datetime         not null
#  creator_id       :integer          
#  entity_id        :integer          
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  locked           :boolean          not null
#  name             :string(255)      not null
#  sales_conditions :text             
#  updated_at       :datetime         not null
#  updater_id       :integer          
#

require 'test_helper'
require "digest/sha2"

class CompanyTest < ActiveSupport::TestCase
  fixtures :companies


  context "A generated company" do

    setup do
      @company, @user = Company.create_with_data({:name=>"Generated LTD", :code=>"gltd"}, {:first_name=>"Gendo", :last_name=>"IKARI", :name=>"gendo", :password=>"12345678", :password_confirmation=>"12345678"}, "fr-FR")
      assert_operator @company.id, :> , 0
      assert_equal @company.currencies.size, 1
    end
    
    should "not be locked" do
      assert !@company.locked
      assert !@user.locked
    end

    should "have valid default document templates" do
      assert_raise Exception do
        @company.print
      end
      for template in @company.document_templates
        if DocumentTemplate.document_natures[template.nature.to_sym].size > 0
          assert_raise ArgumentError do
            @company.print(:id=>template.code)
          end
        else
          assert_nothing_raised do
            @company.print(:id=>template.code)
          end        
        end
        assert_nothing_raised do
          code = DocumentTemplate.compile(template.source, :debug)
          eval(code)
        end
      end
    end

    should "be backed up without prints" do
      assert_raise ArgumentError do
        @company.restore(nil)
      end
      assert_nothing_raised do
        @save_1 = @company.backup(:creator=>"Me")
      end
    end

    context "with sales" do

      setup do
        @sales_order = @company.sales_orders.create!(:client=>@company.entities.third)
      end

      should "invoice its sales" do
        assert !@sales_order.invoice

        line = @sales_order.lines.new(:quantity=>12, :product=>@company.products.first, :warehouse=>@company.warehouses.first)
        assert line.save
        line = @sales_order.lines.new(:quantity=>25, :product=>@company.products.second, :warehouse=>@company.warehouses.first)
        assert line.save
        
        assert @sales_order.reload.propose
        assert_equal @sales_order.state, "ready"
        assert @sales_order.reload.invoice
      end

      should "print its sales" do
        assert_nothing_raised do
          @company.print(:id=>:sales_order, :sales_order=>@sales_order)
        end
      end

    end

    context "with invoiced sales" do

      setup do
        @sales_order = @company.sales_orders.new(:client=>@company.entities.third)
        assert @sales_order.save, @sales_order.errors.inspect
        for y in 0..10
          line = @sales_order.lines.new(:quantity=>rand*50, :product=>@company.products.first, :warehouse=>@company.warehouses.first)
          assert line.save, line.errors.inspect
        end
        assert @sales_order.reload.propose
        assert_equal @sales_order.state, "ready"
        assert @sales_order.reload.invoice
        # line = @sales_order.lines.new(:quantity=>25, :product=>@company.products.second, :warehouse=>@company.warehouses.first)
        # assert line.save, line.errors.inspect
        @sales_invoice = @sales_order.sales_invoices.first
        assert_equal @sales_invoice.class, SalesInvoice
      end

      should "print and archive its sales invoices" do
        data = []
        assert_nothing_raised do
          data << Digest::SHA256.hexdigest(@company.print(:id=>:sales_invoice, :sales_invoice=>@sales_invoice)[0])
        end
        assert_nothing_raised do
          data << Digest::SHA256.hexdigest(@company.print(:id=>:sales_invoice, :sales_invoice=>@sales_invoice)[0])
        end
        assert_nothing_raised do
          data << Digest::SHA256.hexdigest(@company.print(:id=>:sales_invoice, :sales_invoice=>@sales_invoice.id)[0])
        end
        assert_equal data[0], data[1], "The template doesn't seem to be archived"        
        assert_equal data[0], data[2], "The template doesn't seem to be archived or understand Integers"
      end

      should "be backed up and restored" do
        assert_nothing_raised do
          @backup_1 = @company.backup(:creator=>"Me again", :with_prints=>true)
        end

        assert_nothing_raised do
          @backup_2 = @company.backup(:creator=>"Me again", :with_prints=>false)
        end

        assert_nothing_raised do
          assert @company.restore(@backup_1)
        end

        assert_nothing_raised do
          assert @company.restore(@backup_2)
        end
      end

    end


  end


  

end
