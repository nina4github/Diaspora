class Apiv1::PostsController < Apiv1::BaseController
  
    def index
        @aspects = @user.aspects
        @aspects.each do |aspect|
            if aspect.name() == param[:aspectname]
                $posts=aspect.posts
            end
        end                                  
        render :json  => {
             :posts =>    @posts
        }
    end
  
    def show
        render :json  => {
             :posts =>  "test"
        }
    end
end