class Apiv1::ProfilesController < Apiv1::BaseController

    def edit
      puts 'helo'
    end
  
    def index
      render :json => {:actor=>"this is supporse to list all profiles here" } 
    end
  
    #get a users' profile
    def show
		if @user.nil?
			render :json=>{:text => 'user does not exist', :status => 404}
			return
		end
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
                      "category"=>profiletags[0]
        }
        render :json => @response
    end   
    
    def update
        params[:profile] ||= {}
        params[:profile][:first_name]=params[:firstName]
        params[:profile][:last_name]=params[:lastName]  
        params[:profile][:bio]=params[:description]
        params[:profile][:location]=params[:location]
        params[:profile][:tag_string]='#'+params[:category]
        if @user.update_profile params[:profile]
            render :json=>{:text => I18n.t('profiles.update.updated'), :status => 200 , :id=>@user.person.profile.id}
        else
            render :text => I18n.t('profiles.update.failed'), :status => 422 
        end
    end 
end
