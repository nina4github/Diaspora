class Apiv1::ProfilesController < Apiv1::BaseController

    def edit
      puts 'helo'
    end
  
    def index
      render :json => {:actor=>"this is supporse to list all profiles here" } 
    end
  
    #get a users' profile
    def show
        @user=User.find_by_username(params[:id])
        @person = @user.person
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
<<<<<<< HEAD
end
=======
    
    def update
        params[:profile] ||= {}
        params[:profile][:first_name]=params[:firstName]
        params[:profile][:last_name]=params[:lastName]  
        params[:profile][:bio]=params[:description]
        params[:profile][:location]=params[:location]
        params[:profile][:tag_string]=params[:category]
        if @user.update_profile params[:profile]
            render :text => I18n.t('profiles.update.updated'), :status => 200 
        else
            render :text => I18n.t('profiles.update.failed'), :status => 422 
        end
    end 
end
>>>>>>> c0378d2e894863b77fcfe9c328986d582bd4a8c3
