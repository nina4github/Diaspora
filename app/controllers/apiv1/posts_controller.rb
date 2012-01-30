class Apiv1::PostsController < Apiv1::BaseController
  
    def index
        render :json  => {
            :posts => theAspect.posts
        }
    end
  
    def new
        @aspect=theAspect
    end
    
end