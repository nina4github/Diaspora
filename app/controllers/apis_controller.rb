class ApisController < ApplicationController
  authenticate_with_oauth
  before_filter :set_user_from_oauth
  respond_to :json

  def me
    @person = @user.person
    render :json => {
                      :birthday => @person.profile.birthday,
                      :name => @person.name,
                      :uid => @user.username
                    }
  end

  def status
    render :json => {
      :person => @user.person.posts
    }
  end
  
  def posts
    render :json => {
      :person => 'posts list'
    }
  end
  
  def aspects
    @aspects = @user.aspects
    render :json{
      :aspects => @aspect
    }
    
  end
  
  
   def bookmarklet
     @aspects = current_user.aspects
     @selected_contacts = @aspects.map { |aspect| aspect.contacts }.flatten.uniq
     @aspect_ids = @aspects.map{|x| x.id}
     render :layout => nil
   end

   ## POST status_message => text, aspect_ids, photos, services,  
   # taken from StatusMessagesController.rb
   ## support the creation of a new post
   def create
     params[:status_message][:aspect_ids] = params[:aspect_ids]

     normalize_public_flag!

     @status_message = current_user.build_post(:status_message, params[:status_message])

     photos = Photo.where(:id => [*params[:photos]], :diaspora_handle => current_user.person.diaspora_handle)
     unless photos.empty?
       @status_message.photos << photos
     end

     if @status_message.save
       Rails.logger.info("event=create type=status_message chars=#{params[:status_message][:text].length}")

       aspects = current_user.aspects_from_ids(params[:aspect_ids])
       current_user.add_to_streams(@status_message, aspects)
       receiving_services = current_user.services.where(:type => params[:services].map{|s| "Services::"+s.titleize}) if params[:services]
       current_user.dispatch_post(@status_message, :url => short_post_url(@status_message.guid), :services => receiving_services)

       if request.env['HTTP_REFERER'].include?("people") # if this is a post coming from a profile page
          flash[:notice] = t('status_messages.create.success', :names => @status_message.mentions.includes(:person => :profile).map{ |mention| mention.person.name }.join(', '))
        end

       render :json{:create =>'status_messages.create.success '.(@status_message.id), :status => '201'}
       
     else
       unless photos.empty?
         photos.update_all(:status_message_guid => nil)
      end

       render :json {:errors => errors, :status => '422'}
       
     end
   end

   def normalize_public_flag!
     public_flag = params[:status_message][:public]
     public_flag.to_s.match(/(true)|(on)/) ? public_flag = true : public_flag = false
     params[:status_message][:public] = public_flag
     public_flag
   end
  
  
  
  private
  def set_user_from_oauth
    @user = request.env['oauth2'].resource_owner
  end
  
  
   
end
