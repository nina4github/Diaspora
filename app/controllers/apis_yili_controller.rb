class ApisYiliController < ApplicationController
    authenticate_with_oauth
    before_filter :set_user_from_oauth
    respond_to :json

    def me
        @person = @user.person
        render :json => { :birthday => @person.profile.birthday,
                          :name => @person.name,
                          :uid => @user.username
        }
    end
    
    # GET the current user's profile
    def profile
        @person = @user.person
        profile = @person.profile
        profiletags = Array.new
        profile.tags.each do |tag|
          profiletags << tag.name
        end
        @response = { "id"=>profile.id, 
                      "name" => profile.full_name,
                      "nichname" => profile.diaspora_handle,
                      "preferredUsername" =>@user.username,
                      "bithday"=>profile.birthday,
                      "gender"=>profile.gender,
                      "note" => profile.bio,
                      "picture"=>profile.image_url,
                      "tags"=>profiletags
        }
        render :json => {:actor=>@response
                         # :birthday => @person.profile.birthday,
                         # :name => @person.name,
                         # :uid => @user.username
        }
    end

    #create a new user or object
    def newprofile
        user=User.new(params)
        user.password(params[:password])
        user.password_confirmation(params[:password_confirmation]) 
        user.setup(params);
        user.save
        render :json => {
               :mes => "user created"
        }
    end
    
    # GET all posts of the current user
    def posts
        render :json => {
               :posts => @user.person.posts
        }
    end
  
    
    # GET the details of all the aspects the current users
    def aspects
        render :json => {
              :aspects => @user.aspects       
        }
    end
  
    
    # GET all posts within a specific aspect for the a user
    def stream
        @aspects = @user.aspects
        @aspects.each do |aspect|
            if aspect.name == params[:aspectname]
                @posts=aspect.posts
            end
        end    
                                    
        render :json  => {
             :posts =>  @posts
        }
    end
  
    def group_by_criteria
      created_at.to_date.to_s(:db)
    end
  
 
    # GET contacts for an aspect
    def contacts
        @contacts = @user.aspects.find_by_name(params[:aspectname]).contacts
        @response = Hash.new
        @response['actor']=[]
        @contacts.each do |contact|
            profile= contact.person.profile
            @profiletags = Array.new
            profile.tags.each do |tag|
                @profiletags << tag.name
            end
            @response['actor']<<{"id"=>profile.id, 
                          "name" => profile.full_name,
                          "nichname" => profile.diaspora_handle,
                          "preferredUsername" =>User.find(profile.id).username,
                          "bithday"=>profile.birthday,
                          "gender"=>profile.gender,
                          "note" => profile.bio,
                          "picture"=>profile.image_url,
                          "tags"=>@profiletags}
        end
          
        render :json =>{
            :contacts=> @response
        }
    end
 
 
    #get proifles for a list of users
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

  
    # # #  CREATE POST with POST request ## ## ## ## ## ## ## ## ## ## ## 
   
     ## POST status_message => text, aspect_ids, photos, services,  
     # taken from StatusMessagesController.rb
     ## the creation of a new post
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
      
             # if request.env['HTTP_REFERER'].include?("people") # if this is a post coming from a profile page
             # flash[:notice] = t('status_messages.create.success', :names => @status_message.mentions.includes(:person => :profile).map{ |mention| mention.person.name }.join(', '))
             # end
      
             render :json => {:create =>@status_message.guid, :status => '201'}
         else
             unless photos.empty? 
                 photos.update_all(:status_message_guid => nil)
             end
             render :json  => {:errors => errors, :status => '422'}
         end
     end
     # # END POST create # ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## 
  
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
                  :error => 'aspects.create.failure', :status => '422' 
          }
        end
    end
    
    
    # get tags
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
       # 
       # this can upload pictures :)
       # picture =  params['file'] #File.new(params['myfile'])
       # File.open('public/images/' + params['original_filename'], "wb") do |f|
       #   f.write(picture.read)
       #  end
        createphoto()
        photo = @photo
        # respond_to do |format|
        #   format.json{ render(:json => true) }
        # end
    
        #  -- FROM HERE   
        aspect = @user.aspects.find_by_name(params[:aspectname])
        aspect_id = aspect.id
         # for compatibility with the code of StatusMessagesController.rb
        message = Hash.new
        message[:aspect_ids] = [aspect_id]
        message[:public] = false
        message[:text] = "##{params[:aspectname]}"
        current_user=@user
        
        
        photo_post = current_user.build_post(:status_message, message)
        photo_post.photos << photo
        photo_post.save
        
        aspects = [aspect] 
        @user.add_to_streams(photo_post, aspects)
        receiving_services = @user.services.where(:type => params[:services].map{|s| "Services::"+s.titleize}) if params[:services]
        @user.dispatch_post(photo_post, :url => short_post_url(photo_post.guid), :services => receiving_services)
        
        
        respond_to do |format|
            format.json{ render(:layout => false , :json => {"success" => true, "data" => photo}.to_json )}
        end
        # -- TO HERE
        
        #     photos = Photo.where(:id => [*params[:photos]], :diaspora_handle => current_user.person.diaspora_handle)
        #     unless photos.empty?
        #       @status_message.photos << photos
        #     end
        
        #     if @status_message.save
        #       Rails.logger.info("event=create type=status_message chars=#{params[:status_message][:text].length}")
        
        #       aspects = current_user.aspects_from_ids(params[:status_message][:aspect_ids])
        #       current_user.add_to_streams(@status_message, aspects)
        #       receiving_services = current_user.services.where(:type => params[:services].map{|s| "Services::"+s.titleize}) if params[:services]
        #       current_user.dispatch_post(@status_message, :url => short_post_url(@status_message.guid), :services => receiving_services)
    end
  
  
  
    def createphoto
        params[:photo] = Hash.new
        params[:photo][:aspect_ids] = [@user.aspects.find_by_name(params[:aspectname]).id]
        params[:qqfile] = params['original_filename']
        current_user = @user
        params[:photo][:public] = false
        begin
            raise unless params[:photo][:aspect_ids]
  
            if params[:photo][:aspect_ids] == "all"
                params[:photo][:aspect_ids] = current_user.aspects.collect{|x| x.id}
            elsif params[:photo][:aspect_ids].is_a?(Hash)
                params[:photo][:aspect_ids] = params[:photo][:aspect_ids].values
            end
  
            params[:photo][:user_file] = file_handler(params)
             #   file = file_handler(params)
             #   
             #   File.open('testupload/'+params[:original_filename],"wb") do |f|
             #     f.write(open(file.path, "rb") {|io| io.read})
             #   end
             # end
  
             @photo = current_user.build_post(:photo, params[:photo])
             if @photo.save
                  aspects = current_user.aspects_from_ids(params[:photo][:aspect_ids])
         
                  unless @photo.pending
                    current_user.add_to_streams(@photo, aspects)
                    current_user.dispatch_post(@photo, :to => params[:photo][:aspect_ids])
                  end
         
                  if params[:photo][:set_profile_photo]
                    profile_params = {:image_url => @photo.url(:thumb_large),
                                     :image_url_medium => @photo.url(:thumb_medium),
                                     :image_url_small => @photo.url(:thumb_small)}
                    current_user.update_profile(profile_params)
                  end
         
                  # respond_to do |format|
                  #   format.json{ render(:layout => false , :json => {"success" => true, "data" => @photo}.to_json )}
                  # end
                # else
                #   respond_to do |format|
                #      format.json{ render( :json => {"success" => false, "error" => message}.to_json )}
                #    end
             end
         end
     end
  
  
     def file_handler(params)
          ######################## dealing with local files #############
          # get file name
          file_name = params[:qqfile]
          # get file content type
          att_content_type = (request.content_type.to_s == "") ? "application/octet-stream" : request.content_type.to_s
          # create tempora##l file
          begin
            file = Tempfile.new(file_name, {:encoding =>  'BINARY'})
            file.print request.raw_post.force_encoding('BINARY')
          rescue RuntimeError => e
            raise e unless e.message.include?('cannot generate tempfile')
            file = Tempfile.new(file_name) # Ruby 1.8 compatibility
            file.binmode
            file.print request.raw_post
          end
          # put data into this file from raw post request
  
          # create several required methods for this temporal file
          Tempfile.send(:define_method, "content_type") {return att_content_type}
          Tempfile.send(:define_method, "original_filename") {return file_name}
          file
     end
  
  
     private
     def set_user_from_oauth
       @user = request.env['oauth2'].resource_owner
     end
   
end
