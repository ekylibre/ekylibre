require 'test_helper'
require 'performance_test_help'

class BrowsingTest < ActionController::PerformanceTest

  # Try to call every under-control actions
  def self.perform_all_actions(options={})
    code  = ""
    code += "context 'A connected user' do\n\n"
    code += "  setup do\n"
    code += "    @user = users(:users_001)\n"
    code += "    @company = companies(:companies_001)\n"
    code += "    get \"session/new\"\n"
    code += "    assert_response :success\n"
    code += "  end\n"

    code += "  should 'perform_all' do\n"
    for controller, useable_actions in User.rights.sort{|a,b| a[0].to_s<=>b[0].to_s}
      # code += "\n  # #{controller}\n"
      # code += "  @user = users(:users_001)\n"
      # code += "  @company = companies(:companies_001)\n"
      # code += "  get \"session/new\"\n"
      # code += "  assert_response :success\n"
      # code += "  post \"session\", :name=>@user.name, :password=>@user.comment\n"
      # code += "  assert_response :redirect\n"

      for action in useable_actions.keys.sort{|a,b| a.to_s<=>b.to_s}.delete_if{|x| ![:index, :new, :create, :edit, :update, :destroy, :show].include?(x.to_sym)} # .delete_if{|x| except.include? x}
        # .delete_if{|x| ![:index, :show].include?(x.to_sym)}
        
        action_name = action.to_s
        mode = if action_name.match(/^(index)$/) # GET without ID
                 :index
               elsif action_name.match(/^(new)$/) || action_name.match(/^list($|_\w+$)/)# GET with ID
                 :new
               elsif action_name.match(/^(show|edit)$/) # GET with ID
                 :show
               elsif action_name.match(/^(create|load)$/) # POST without ID
                 :create
               elsif action_name.match(/^(update)$/) # PUT with ID
                 :update
               elsif action_name.match(/^(destroy)$/) # DELETE with ID
                 :destroy
               elsif action_name.match(/^(duplicate|up|down|lock|unlock|increment|decrement|propose|confirm|refuse|invoice|abort|correct|finish|propose_and_invoice|sort)$/) # POST with ID 
                 :touch
               end
        model = controller.to_s.singularize
      
        req = if mode == :index
                "get '/#{controller}'"
              elsif mode == :new
                "get '/#{controller}/#{action_name}'"
              elsif mode == :show
                "get '/#{controller}/1'"
              elsif mode == :create
                "post '/#{controller}'"
              elsif mode == :update
                "put '/#{controller}/1'"
              elsif mode == :destroy
                "delete '/#{controller}/2'"
              elsif mode == :touch
                "post '/#{controller}/1/#{action_name}'"
              end
        unless req.blank?
          # code += "\n  should '#{req.split(/\s/)[0]} #{controller}##{action_name}' do\n"
          code += "    "+req+"\n"
          # code += "  end\n"
        end
      end

    end
    code += "  end\n"
    code += "end\n"

    list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
    class_eval(code)
  end

  perform_all_actions

end
