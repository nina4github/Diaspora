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
        profiletags = Array.new
        profile.tags.each do |tag|
            profiletags << tag.name
        end
        @response = { "id"=>profile.id, 
                      "firstName" => profile.first_name,
                      "lastName" => profile.last_name,
                      "description" => profile.bio,
                      "picture"=>profile.image_url,
                      "location"=>profile.location,
                      "catogery"=>profiletags
        }
        render :json => {:thing=>@response }
    end   
    
<<<<<<< HEAD
end
=======
    def edit
        
    end 
end
>>>>>>> ab030bb3c6f2ef20c64d13025796c9578c296697
