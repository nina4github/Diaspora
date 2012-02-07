class Apiv1::ContactsController < Apiv1::BaseController
  
    # GET all posts within a specific aspect for the current user
    def index
        @contacts = theAspect.contacts
        @response = Hash.new
        @response['actor']=[]
        @contacts.each do |contact|
            profile= contact.person.profile
            @profiletags = Array.new
            profile.tags.each do |tag|
                @profiletags << tag.name
            end
            @response['actor']<<{"id"=>profile.id, 
                          "name" => profile.full_name,
                          "nichname" => profile.diaspora_handle,
                          "preferredUsername" =>User.find(profile.id).username,
                          "bithday"=>profile.birthday,
                          "gender"=>profile.gender,
                          "note" => profile.bio,
                          "picture"=>profile.image_url,
                          "tags"=>@profiletags}
        end
          
        render :json =>{
            :contacts=> @response
        }
    end
    
    def show
        contact=Contact.find_by_user_id(params[:uid])
        aspect=theAspect()
        @user.add_contact_to_aspect(contact,aspect)
    end
end