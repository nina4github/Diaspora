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
    @contacts = @user.aspects.find_by_name(params[:aspect_name]).contacts
      
    @cp = User.includes(:aspects => {:contacts => {:person => :profile}}).where(User.arel_table[:id].eq(3).and(Aspect.arel_table[:name].eq(params[:aspect_name])))
      
   render :json =>{
     :contacts=> @contacts, 
     :contactsprofiles=> @cp}
   
 end
 
 def profiles
#   @person_ids= params[:ids].
   @person_ids = params[:ids].split("[")[1].split("]")[0].split(",").map { |s| s.to_i }
   @profiles = Hash.new
   
   @person_ids.each do |person_id|
     @profiles[person_id] = Person.find_by_owner_id(person_id).profile
   end
   render :json =>{
    :profiles => @profiles
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
     params[:status_message][:aspect_ids] = [aspect_id]
     params[:status_message][:public] = false
     current_user=@user


     @status_message = current_user.build_post(:status_message, params[:status_message])

     photos = Photo.where(:id => [*params[:photos]], :diaspora_handle => current_user.person.diaspora_handle)
     unless photos.empty?
       @status_message.photos << photos
     end

     if @status_message.save
       Rails.logger.info("event=create type=status_message chars=#{params[:status_message][:text].length}")

       aspects = current_user.aspects_from_ids(params[:status_message][:aspect_ids])
       current_user.add_to_streams(@status_message, aspects)
       receiving_services = current_user.services.where(:type => params[:services].map{|s| "Services::"+s.titleize}) if params[:services]
       current_user.dispatch_post(@status_message, :url => short_post_url(@status_message.guid), :services => receiving_services)

#       if request.env['HTTP_REFERER'].include?("people") # if this is a post coming from a profile page
#          flash[:notice] = t('status_messages.create.success', :names => @status_message.mentions.includes(:person => :profile).map{ |mention| mention.person.name }.join(', '))
#        end

       render :json => {:create =>@status_message.guid, :status => '201'}
       
     else
       unless photos.empty?
         photos.update_all(:status_message_guid => nil)
      end

       render :json  => {:errors => errors, :status => '422'}
       
     end
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
    
  
  
  
  
  
  
  ##
  # TAGs
  # get tags
  #
  ##
  def tags
    params[:tag_name].downcase!

   @result = findtags(params[:tag_name],params[:max_time], params[:only_posts], params[:page])
   render :json => {:tagfeed=> @result}
   
  end
  
  def activities
    params[:activity_name].downcase!
    # @posts = findtags(params[:activity_name],params[:max_time], "true", params[:page]) # retrieve only posts
    
    # take only the posts from my contacts
    contacts = @user.aspects.find_by_name(params[:activity_name]).contacts
    i=0
    contact_ids = Array.new
    for contact in contacts
      contact_ids[i] = contact.person.id
      i=i+1
    end
    
    
    #GET POSTS
#    @aspect = :tag
    @posts = StatusMessage.
      includes(:mentions).
      joins("LEFT OUTER JOIN post_visibilities ON post_visibilities.post_id = posts.id").
      joins("LEFT OUTER JOIN contacts ON contacts.id = post_visibilities.contact_id").
      where(Contact.arel_table[:user_id].eq(@user.id).or(
        StatusMessage.arel_table[:public].eq(true).or(
          StatusMessage.arel_table[:author_id].eq(@user.person.id)
        )).or(:mention => {:person_id => contact_ids})).select('DISTINCT posts.*')

#    params[:prefill] = "##{params[:activity_name]} "
    @posts = @posts.tagged_with(params[:activity_name])

    max_time = params[:max_time] ? Time.at(params[:max_time].to_i) : Time.now
    @posts = @posts.where(StatusMessage.arel_table[:created_at].lt(max_time))
    @posts = @posts.includes({:author => :profile}, :comments, :photos).order('posts.created_at DESC').limit(15)
    #
    
    render :json => {:posts => @posts}
  end

  def findtags(name, max_time, only_posts, page )
   
    @aspect = :tag
    if current_user
      @posts = StatusMessage.
        joins("LEFT OUTER JOIN post_visibilities ON post_visibilities.post_id = posts.id").
        joins("LEFT OUTER JOIN contacts ON contacts.id = post_visibilities.contact_id").
        where(Contact.arel_table[:user_id].eq(current_user.id).or(
          StatusMessage.arel_table[:public].eq(true).or(
            StatusMessage.arel_table[:author_id].eq(current_user.person.id)
          )
        )).select('DISTINCT posts.*')
    else
      @posts = StatusMessage.all_public
    end

    params[:prefill] = "##{params[:name]} "
    @posts = @posts.tagged_with(name)

    max_time = max_time ? Time.at(max_time.to_i) : Time.now
    @posts = @posts.where(StatusMessage.arel_table[:created_at].lt(max_time))
    @posts = @posts.includes({:author => :profile}, :comments, :photos).order('posts.created_at DESC').limit(15)
    #@posts = @posts.includes({:author => :profile}, :comments, :photos).order('posts.created_at DESC').limit(15)

    @commenting_disabled = true

    if only_posts == 'true'
      #render :partial => 'shared/stream', :locals => {:posts => @posts}
      #render :json => {:posts => @posts}
      return @posts
    else
      profiles = Profile.tagged_with(name).where(:searchable => true).select('profiles.id, profiles.person_id')
      @people = Person.where(:id => profiles.map{|p| p.person_id}).paginate(:page => page, :per_page => 15)
      @people_count = Person.where(:id => profiles.map{|p| p.person_id}).count
      #render :json => {:people => @people}
      return @people
    end
    
  end  
  
  
  
   private
   def set_user_from_oauth
     @user = request.env['oauth2'].resource_owner
   end
end
