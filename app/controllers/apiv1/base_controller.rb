class Apiv1::BaseController < ApplicationController
    #authenticate_with_oauth
    before_filter :set_user_from_oauth
    respond_to :json
    
    def set_user_from_oauth
         #@user = request.env['oauth2'].resource_owner
         @user=User.find_by_username(params[:user])
    end
end