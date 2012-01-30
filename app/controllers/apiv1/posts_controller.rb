class Apiv1::PostsController < Apiv1::BaseController
  
    def index
        aspects = @user.aspects
        @activity = params[:aspectname]
      
        @stream = retrieve_stream(@activity,@user.id)
        @stream = @stream.sort{|a,b| b.created_at <=> a.created_at }
        @stream = convert_to_activity_stream(@stream)
                                                          
        render :json  => {
           :posts => @stream,
        }
    end
  
    def show
        render :json  => {
             :posts =>  "test"
        }
    end
end