class Apiv1::PostsController < Apiv1::BaseController
  
    def index
        @posts = @user.aspects.find_by_name(params[:id]).posts                                    
        render :json  => {
             :posts =>  @posts
        }
    end
  
    def show
        render :json  => {
             :posts =>  "test"
        }
    end
end