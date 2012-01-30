class Apiv1::AspectsController < Apiv1::BaseController
    
    # GET a list of all aspects for a user
    def index
        render :json => {
              :aspects => @user.aspects       
        }
    end
    
end