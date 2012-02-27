class Apiv1::PostsController < Apiv1::BaseController
  
    def index
        render :json  => {
            :posts => theAspect.posts
        }
    end
  
    def create
        aspect =theAspect()
        aspect_id = aspect.id
        # for compatibility with the code of StatusMessagesController.rb
        params[:status_message][:aspect_ids] = [aspect_id]
        params[:status_message][:public] = false
        params[:status_message][:text] = params[:text]
        current_user=@user

        @status_message = current_user.build_post(:status_message, params[:status_message])    
        if @status_message.save
             Rails.logger.info("event=create type=status_message chars=#{params[:status_message][:text].length}")
             aspects = current_user.aspects_from_ids(params[:status_message][:aspect_ids])
             current_user.add_to_streams(@status_message, aspects)
             render :json => {:create =>@status_message.guid, :status => '201'}
        end
    end
    
end