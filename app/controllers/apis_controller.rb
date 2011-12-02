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
  
  
  # GET aspects
  # GET the details of all the aspects the current users
  # it also lists the contacts that have visibility right on that aspect
  def aspects
    render :json => {
      :aspects => @user.aspects       
    }
  end
  
  
  
 
  
  # GET all posts within a specific aspect, the aspect belongs to the current user
  def stream
    aspects = @user.aspects
    @activity = params[:aspectname]
    
    #ids = [aspects.find_by_name(@activity).id]
    
    @stream = retrieve_stream(@activity,@user.id)
    @stream = convert_to_activity_stream(@stream)
                                                      
    render :json  => {
       :stream => @stream,
      # :activitystream=> @stream
    }
    
  end
  
  
  # to check
  def last
   aspects = @user.aspects
   ids = [aspects.find_by_name(params[:aspectname]).id]
   @activity = params[:aspectname]
  
   @stream = retrieve_stream(@activity,@user.id)
    msgs = Hash.new
    @response = Array.new
      
      #take the message of which id is author
    @stream.each do |p|
      if msgs[p.author_id].nil?
          msgs[p.author_id] = [p]
      else
          msgs[p.author_id] <<p
      end      
    end 
       #h.each {|key, value| puts "#{key} is #{value}" }
       msgs.each do |key,value| 
         @response << value #convert_to_activity_stream(value)
        
       end
      
      
    #end
    
    # return a list of the last status for each member of the aspect, the user included
      render :json  =>{
         :stream => @response}
    
  end
  
  
  
 
  # GET contacts for an aspect
  # (review 17Nov2011)
  def contacts
    @contacts = @user.aspects.find_by_name(params[:aspectname]).contacts
    @response = Array.new
    @contacts.each do |contact|
      @response<<contact.person.profile
      
    end
      
   render :json =>{
     :contacts=> @response
     }
 end
 
 
 def profiles
   @person_ids = JSON.parse(params[:ids])
   @profiles = Array.new
   @person_ids.each do |person_id|
     @profiles << Person.find_by_owner_id(person_id).profile
   end
   render :json =>{
    :profiles => @profiles
   }
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
    # cut and paste from tag_controller
   @result = findtags(params[:tag_name],params[:max_time], params[:only_posts], params[:page])
   render :json => {:tagfeed=> @result}
   
  end
  
  
  def activities
    params[:activity_name].downcase!
    
    # take only the posts from my contacts
    contacts = @user.aspects.find_by_name(params[:activity_name]).contacts
    i=0
    contact_ids = Array.new
    for contact in contacts
      contact_ids[i] = contact.person.id
      i=i+1
    end
    
    
    # refinement from tag_controller
    #GET POSTS
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
  
  
  # works
  #POST create a new group defined with an activityname = aspect name and an array of user_ids that will share this aspect 
  # reciprocal construction of an aspect
  # params[:users] = array of users ids
  # params[:activity] = string with the name of the aspect to create
  #
  # USERS MUST have already been created!!
  #
  def group
    
    @user_ids = JSON.parse(params[:users]) # array of ids
    @aspect_name = params[:activity]+' ' # string
    
    # for each user I need to create a new aspect with this name 
    #   if it does not exists already create it
    #   else do nothing
    #   I need to add the users as contacts
    #   if they are already included do nothing
    #   else add contacts to aspect 
    
    @response = Array.new
    @tmp_ids = @user_ids 
    @user_ids.each do |user|
      tmp_user = User.find(user)
     
      if tmp_user.aspects.find_by_name(params[:activity]).nil?
        @aspect = tmp_user.aspects.create(:name => params[:activity])  
      else
        @aspect = tmp_user.aspects.find_by_name(params[:activity])
      end
      if @aspect.valid?
        # foreach user_ids (different than the current one :))
        @tmp_ids.each do |id|
          if user!=id # I do this with all the ids, except the user I am creating the aspect for
            @person = Person.find(id)
            @contact = tmp_user.contact_for(@person)
            if !@contact.nil?  
              if @contact.aspects.where(:id =>@aspect.id).nil?
                @contact.aspects << @aspect
              end
            else
              @contact = tmp_user.share_with(@person, @aspect)
            end
          end
        end # end add contacts cycle
        @response << "new activity group "+ @aspect.name+" for "+tmp_user.username
      end
    end # end add aspect cycle
    render :json => {'response'=>@response}
  end
  
  
  
 def upload
  # picture = JSON.parse(params['myfile'])
  #   picture.rewind
#  picture = StringIO.new(Base64.decode64(params['myfile']['tempfile']))

   picture =  params['file'] #File.new(params['myfile'])
   File.open('public/images/' + params['original_filename'], "wb") do |f|
     f.write(picture.read)
    end
   render :json => {'response' => 'everything ok, file uploaded'}
  end
  
  
   private
   def set_user_from_oauth
     @user = request.env['oauth2'].resource_owner
   end
   
   
   # 
   # retrieve the visible posts for a user in a specific aspect and filtered by a specific tag
   # the tag filter is used to guarantee the topic of the message match the topic of the aspect
   # the stream has to be filled with photos because they do not have a tag when they are created but they are associated to a statusmessage through the GUID and STATUS_MESSAGE_GUID fields in Post
   # 
   # aspect_name = string with the name of the activity on focus (for aspect and tag filtering)
   # user_id = id of the user from which to control the visibility of the posts
   # return stream
   #
   # todo => review how photos are created
   def retrieve_stream(aspect_name,user_id)
     
     # I had to recreate the stream object, because it was almost impossible to understand what exactly RUBY is doing behind the scenes
     # Here the stream includes ALL the StatusMessages that a user
     
     posts = Post.joins(:post_visibilities,:aspect_visibilities, :aspects, :contacts,'INNER JOIN taggings ON taggings.taggable_id = posts.id','INNER JOIN tags ON taggings.tag_id = tags.id').where(:aspects=>{:name=>aspect_name},:tags=>{:name=>aspect_name}).where('posts.author_id = '+user_id.to_s+' OR contacts.user_id ='+user_id.to_s).order('posts.created_at DESC').select('DISTINCT posts.*,tags.name as tags_name, aspects.id as aspects_id, aspects.name as aspects_name')
     # I need to do a trick for extracting the photos considering that they do not have a tag, but are linked to a status message that has one... no comment on the DIASPORA decisions of implementation please
     statusmessage_guids = Array.new
     # take all the posts that I just collected and take their GUID (really I have no clue what this is!!)
     posts.each do |p|
     	statusmessage_guids<<p.guid
     end
     # select all the posts of type photo that match the field Status_message_guid with the array we just extracted
     photos = Post.where(:type=>'Photo',:status_message_guid=>statusmessage_guids).select('posts.*')

     stream = Array.new
     posts.each do |p|
       stream << p
     end
     photos.each do |p|
       stream << p 
     end
     stream = stream.sort{|a,b| b.created_at <=> a.created_at }
     return stream 
   end
   
   
   def convert_to_activity_stream(stream)
     # transform to activity stream 
       # "items": [
       #         {
       #           "id": "456",
       #           "published": "2011-02-10T15:04:55Z",
       #           "actor": {
       #             "id": "42",
       #             "displayName": "Jane Doe",
       #             "name": "Jane Doe",
       #             "nickname": "jane@pod.example.org",
       #             "preferredUsername": "jane",
       #             "birthday": "1975-02-14",
       #             "gender": "who knows",
       #             "note": "Janes profile description"
       #             "picture": "http://example.com/uploads/images/foo.png"
       #           },
       #           "verb": "post",
       #           "object": {
       #             "content": "Hello, epic Diasporaverse"
       #           }
       #         }, 
     @response = Array.new
     stream.each do |msg|
         @item = Hash.new
         
                   # build item
                                                        @item['id']=msg.id
                                                        @item['published']=msg.created_at
                                                        @item['actor']={"id"=>msg.author_id, 
                                                                        "displayName" => Profile.find(msg.author_id).full_name,
                                                                        "name" => Profile.find(msg.author_id).full_name,
                                                                        "nichname" => Profile.find(msg.author_id).diaspora_handle,
                                                                        "preferredUsername" =>User.find(msg.author_id).username,
                                                                        "bithday"=>Profile.find(msg.author_id).birthday,
                                                                        "gender"=>Profile.find(msg.author_id).gender,
                                                                        "note" => Profile.find(msg.author_id).bio,
                                                                        "picture"=>Profile.find(msg.author_id).image_url}
                                                        @item['verb']=Post.find(msg.id).type
                                                        if (@item['verb']=='Photo')
                                                          @tags = Array.new
                                                        else
                                                          @tags = Array.new
                                                          msg.tags.each do |tag|
                                                            @tags << tag.name
                                                          end
                                                        end
                                                        @item['object']={
                                                          "objectType"=>"activity",
                                                          "content" => msg.text,
                                                          "tags" => @tags}
                   
            @response << @item   
          end
          return @response 
   end
   
end
