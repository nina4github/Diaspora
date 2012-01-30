class Apiv1::PostsController < Apiv1::BaseController
  
    # GET all posts within a specific aspect for the current user
    def index
        @posts = @user.aspects.find_by_name(params[:id]).posts                                    
        render :json  => {
             :posts =>  @posts
        }
    end
    
end