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
			if !user.email.nil?
				feedId=user.email.split("@").first
			end
			newuser={"id"=>user.id, "username"=>user.username, "feedId"=>feedId}
            users << newuser
        end
		feedId=''
		if !@user.email.nil?
			feedId=@user.email.split("@").first
		end
		me={"id"=>@user.id, "username"=>@user.username,"feedId"=>feedId}
		users << me
        render :json =>{:user=>users}
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