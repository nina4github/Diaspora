class Apiv1::BaseController < ActionController::Base
    authenticate_with_oauth
    before_filter :set_user_from_oauth
    respond_to :json
    
    def set_user_from_oauth
         @user = request.env['oauth2'].resource_owner
    end
end