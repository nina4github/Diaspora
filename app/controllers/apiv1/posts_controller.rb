class Apiv1::PostsController < Apiv1::BaseController
  
    def index
        render :json  => {
            :posts => theAspect.posts
        }
    end
  
    def create
        ids=Array.new
        aspects = @user.aspects
        if params[:aspect]
            aspects.each do |aspect|
                 if aspect.name.downcase == params[:aspect].downcase
                     ids.push aspect.id
                 end
             end    
        else
            aspects.each do |aspect|
                ids.push aspect.id
            end
        end
        # for compatibility with the code of StatusMessagesController.rb
        params[:status_message]={}
        params[:status_message][:aspect_ids] = ids
        params[:status_message][:public] = false
        params[:status_message][:text] = params[:text]
        current_user=@user

        @status_message = current_user.build_post(:status_message, params[:status_message])    
        if @status_message.save
             Rails.logger.info("event=create type=status_message chars=#{params[:status_message][:text].length}")
             aspects = current_user.aspects_from_ids(params[:status_message][:aspect_ids])
             current_user.add_to_streams(@status_message, aspects)
             receiving_services = current_user.services.where(:type => params[:services].map{|s| "Services::"+s.titleize}) if params[:services]
             current_user.dispatch_post(@status_message, :url => short_post_url(@status_message.guid), :services => receiving_services)
             render :json => {:id =>@status_message.id, :status => '200'}
        end
    end
    
end