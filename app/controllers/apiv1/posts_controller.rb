class Apiv1::PostsController < Apiv1::BaseController
  
    def index
        render :json  => {
            :posts => theAspect.posts
        }
    end
  
    def create
        @aspect=theAspect
    end
    
end