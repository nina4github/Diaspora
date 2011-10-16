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

  # GET all posts of the current user
  def posts
    render :json => {
      :posts => @user.person.posts
    }
  end
  
  # GET all posts within a specific aspect, the aspect belongs to the current user
  def aspect_posts
    aspects = @user.aspects
    aspect=aspects.find_by_name(params[:aspect_name])
    aspect_ids = [aspect.id] 
    @stream = AspectStream.new(@user, aspect_ids,
                               :order => "created_at",
                               :max_time => Time.now.to_i)
    
    render :json  => {
      :aspect_posts_mine => aspect.posts,
      :aspect_posts_stream => @stream.posts
    }
  end
  
  # GET the details of all the aspects the current users
  # it also lists the contacts that have visibility right on that aspect
  def aspects
    render :json => {
      :aspects => @user.aspects       
    }
  end
    
 
  # GET contacts for an aspect
  def contacts
   render :json =>{
     :contacts=> @user.aspects.find_by_name(params[:aspect_name]).contacts
   }
 end
  # GET everything for an aspect
  def aspect  
    render :json =>{
      :aspect => @user.aspects.find_by_name(params[:aspect_name])
    }
  end

  

  def bookmarklet
       @aspects = current_user.aspects
       @selected_contacts = @aspects.map { |aspect| aspect.contacts }.flatten.uniq
       @aspect_ids = @aspects.map{|x| x.id}
       render :layout => nil
     end
  
# # #  CREATE POST with POST request ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## #
   
   ## POST status_message => text, aspect_ids, photos, services,  
   # taken from StatusMessagesController.rb
   ## support the creation of a new post
   def create
     aspect = @user.aspects.find_by_name(params[:aspect_name])
     aspect_id = aspect.id
     # for compatibility with the code of StatusMessagesController.rb
     params[:status_message][:aspect_ids] = aspect_id
     current_user=@user
     normalize_public_flag!

     @status_message = current_user.build_post(:status_message, params[:status_message])

     #photos = Photo.where(:id => [*params[:photos]], :diaspora_handle => current_user.person.diaspora_handle)
     #unless photos.empty?
       #@status_message.photos << photos
     #end

     if @status_message.save
       Rails.logger.info("event=create type=status_message chars=#{params[:status_message][:text].length}")

       aspects = current_user.aspects_from_ids(params[:aspect_ids])
       current_user.add_to_streams(@status_message, aspects)
       receiving_services = current_user.services.where(:type => params[:services].map{|s| "Services::"+s.titleize}) if params[:services]
       current_user.dispatch_post(@status_message, :url => short_post_url(@status_message.guid), :services => receiving_services)

       if request.env['HTTP_REFERER'].include?("people") # if this is a post coming from a profile page
          flash[:notice] = t('status_messages.create.success', :names => @status_message.mentions.includes(:person => :profile).map{ |mention| mention.person.name }.join(', '))
        end

       render :json => {:create =>@status_message.guid, :status => '201'}
       
     else
       unless photos.empty?
         photos.update_all(:status_message_guid => nil)
      end

       render :json  => {:errors => errors, :status => '422'}
       
     end
   end

   def normalize_public_flag!
     public_flag = params[:status_message][:public]
     public_flag.to_s.match(/(true)|(on)/) ? public_flag = true : public_flag = false
     params[:status_message][:public] = public_flag
     public_flag
   end
  
# # END POST create # ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## #
  
  # POST a new aspect for a user
  # modified from aspects_controller.rb
  def newaspect
    current_user=@user
    params[:aspect][:user_id]=@user.id
    @aspect=current_user.aspects.create(params[:aspect])
    if @aspect.valid?
   
   #controls if I am adding an aspect with or without a person to attach to it! GENIAL :D
      if params[:aspect][:person_id].present?
        @person = Person.where(:id => params[:aspect][:person_id]).first

        if @contact = current_user.contact_for(@person)
          @contact.aspects << @aspect
        else
          @contact = current_user.share_with(@person, @aspect)
        end
      end
      render :json => {:create => @aspect.name, :status => '201'}
    else
      render :json =>{
        :error => 'aspects.create.failure', :status => '422' }
    end
  end
    
  
  private
  def set_user_from_oauth
    @user = request.env['oauth2'].resource_owner
  end
  
  
   
end
