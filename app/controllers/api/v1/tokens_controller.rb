# encoding: utf-8
# == License
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2014 Brice Texier
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Api::V1::TokensController < Api::V1::BaseController
  skip_before_action :authenticate_api_user!

  def create
    puts "???".green
    email, password = params[:email], params[:password]

    if email.blank? or password.blank?
      render status: :bad_request, json: {message: "The request must contain the user email and password."}
      return
    end

    unless @user = User.find_by(email: email.downcase)
      logger.info("User #{email} failed signin, user cannot be found.")
      puts "???".red
      render status: :unauthorized, json: {message: "Invalid email or password."}
      return
    end

    if @user.valid_password?(password)
      # This following line forbids simultaneous connections:
      # @user.authentication_token = User.generate_authentication_token
      @user.save!
      render json: {token: @user.authentication_token}
    else
      puts "???".blue
      logger.info("User #{email} failed signin, password is invalid")
      render status: :unauthorized, json: {message: "Invalid email or password."}
    end
  end

  def destroy
    if @user = User.find_by(authentication_token: params[:id])
      @user.authentication_token = nil
      @user.save!
      render status: :success, json: {token: params[:id]}
    else
      logger.info("Token not found.")
      render status: :not_found, json: {message: "Invalid token."}
    end
  end

end
