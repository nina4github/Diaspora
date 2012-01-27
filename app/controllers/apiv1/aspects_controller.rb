class Apiv1::AspectsController < Apiv1::BaseController
  
    # GET a list of all aspects for a user
    def index
        render :json => {
              :aspects => @user.aspects       
        }
    end
    
    # GET all posts within a specific aspect for the current user
    def posts
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
    
    # GET all posts within a specific aspect for the current user
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
end