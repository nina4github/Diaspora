class BaseController
    authenticate_with_oauth
    before_filter :set_user_from_oauth
    respond_to :json
    
    protected
    
    def set_user_from_oauth
        @user = request.env['oauth2'].resource_owner
    end
end