class Apiv1::ProfilesController < Apiv1::BaseController

    def edit
      puts 'helo'
    end
  
    def index
      render :json => {:actor=>"this is supporse to list all profiles here" } 
    end
  
    #get a users' profile
    def show
        @person = @user.person
        profile = @person.profile
        @response = [ "id"=>profile.id, 
                      "firstName" => profile.first_name,
                      "lastName" => profile.last_name,
                      "description" => profile.bio,
                      "picture"=>profile.image_url,
                      "location"=>profile.location,
                      "catogery"=>profile.tags[0].name
        ]
        render :json => {:thing=>@response }
    end   
end
