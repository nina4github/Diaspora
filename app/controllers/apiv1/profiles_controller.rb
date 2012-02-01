class Apiv1::ProfilesController < Apiv1::BaseController

    def edit
      puts 'helo'
    end
  
    def index
      render :json => {:actor=>"this is supporse to list all profiles here" } 
    end
  
    #get a users' profile
    def show
        if @user==nil
            render :json =>{ :text => I18n.t('User does not exist!'), :status => 422 }
        end
        @person = @user.person
        profile = @person.profile
        profileTags=profile.tags;
        @response = [ "id"=>profile.id, 
                      "firstName" => profile.first_name,
                      "lastName" => profile.last_name,
                      "description" => profile.bio,
                      "picture"=>profile.image_url,
                      "location"=>profile.location,
                      "catogery"=>profileTags[0].name
        ]
        render :json => {:thing=>@response }
    end   
end
