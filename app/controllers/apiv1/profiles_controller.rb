class Apiv1::ProfilesController < Apiv1::BaseController
  
    #get a users' profile
    def show
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
        render :json => {:actor=>@response }
    end
    
    def new
        user=User.new
        user.password=params[:password]
        user.password_confirmation=params[:password_confirmation]
        user.setup(params)
        if user.save
            user.seed_aspects
            mes=I18n.t 'registrations.create.success'
        else
            user.errors.delete(:person)
            mes=user.errors.full_messages.join(";")
        end
        render :json => {
               :mes => mes
        }
    end
    
end