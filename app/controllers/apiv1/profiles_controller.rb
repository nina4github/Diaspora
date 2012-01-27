class Apiv1::ProfilesController < Apiv1::BaseController
  
    #get a users' profile
    def show
        if params[:id]!=0
            @user=User.find_by_id(params[:id])
        end
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
    
end