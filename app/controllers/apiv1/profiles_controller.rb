class Apiv1::ProfilesController < Apiv1::BaseController
  
    def index
      render :json => {:actor=>"this is supporse to list all profiles here" } 
    end
  
    #get a users' profile
    def show
        @person = @user.person
        profile = @person.profile
        profile.tags.each do |tag|
            category << tag.name
        end
        @response = [ "id"=>profile.id, 
                      "firstName" => profile.first_name,
                      "lastName" => profile.last_name,
                      "description" => profile.bio,
                      "picture"=>profile.image_url,
                      "location"=>profile.location,
                      "catogery"=>category
        ]
        render :json => {:thing=>@response }
    end   
    
    def edit
        
    end 
end