class Apiv1::ContactsController < Apiv1::BaseController
  
    # GET all contacts within a specific aspect for the current user
    def index
        @contacts = theAspect.contacts
        @uid=[]
		@pid=[]
        @contacts.each do |contact|
			@pid << contact.person_id
            @uid << contact.person.owner_id 
        end
        #self id
		@pid << @user.person.id
        @uid << @user.id		
        render :json =>{
            :uid=> @uid, :pid=>@pid
        }
    end
	
	def all
        @contacts = theAspect.contacts
        users=[]
        @contacts.each do |contact|
			user=User.find_by_id(contact.person.owner_id)
			newuser={"id"=>user.id, "username"=>user.username, "feedId"=>user.email}
            users << newuser
        end
		me={"id"=>@user.id, "username"=>@user.username,"feedId"=>@user.email}
		users << me
        render :json => users
    end
	
    
    def create
        @ids=params[:ids]
        @aspect = theAspect()
        
        @ids.each do |id|
            @person = Person.find(id)
            @contact = @user.contact_for(@person)
            if @contact.nil?
                @user.share_with(@person, @aspect)
            else
                @user.add_contact_to_aspect(@contact, @aspect)
            end
        end
    end
end