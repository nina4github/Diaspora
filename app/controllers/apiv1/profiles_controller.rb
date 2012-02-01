class Apiv1::ProfilesController < Apiv1::BaseController
  
    def index
      render :json => {:actor=>"this is supporse to list all profiles here" } 
    end
  
    #get a users' profile
    def show
        @person = @user.person
        if @person==nil
            render :json =>{ :text => I18n.t('User does not exist!'), :status => 422 }
        end
        profile = @person.profile
        profiletags = Array.new
        profile.tags.each do |tag|
            profiletags << tag.name
        end
        @response = [ "id"=>profile.id, 
                      "firstName" => profile.first_name,
                      "lastName" => profile.last_name,
                      "description" => profile.bio,
                      "picture"=>profile.image_url,
                      "location"=>profile.location,
                      "catogery"=>profiletags[0]
        ]
        render :json => {:thing=>@response }
    end   
    
    def edit
        
    end 
end