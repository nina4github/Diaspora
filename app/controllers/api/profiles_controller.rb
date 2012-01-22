class Api::ProfilesController < ApplicationController
    authenticate_with_oauth
    before_filter :set_user_from_oauth
    respond_to :json
      
    def set_user_from_oauth
        @user = request.env['oauth2'].resource_owner
    end    
    def show
        if params[:id]!=0
            @user=User.find(params[:id])
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