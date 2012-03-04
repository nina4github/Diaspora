class Apiv1::ContactsController < Apiv1::BaseController
  
    # GET all contacts within a specific aspect for the current user
    def index
        @contacts = theAspect.contacts
        @uid=[]
		@pid=[]
		@cid=[]
        @contacts.each do |contact|
			@cid << contact.id
			@pid << contact.person_id
            @uid << contact.user_id 
        end
        #self id
		@pid << @user.person.id
        @uid << @user.id		
        render :json =>{
            :uid=> @uid, :pid=>@pid, :cid=>@cid
        }
    end
    
    def create
        @ids=params[:ids]
        @aspect = theAspect()
        
        @ids.each do |id|
            @person = Person.find(id)
            @contact = @user.contact_for(@person)
            if $contact.nil?
                @user.share_with(@person, @aspect)
            else
                @user.add_contact_to_aspect(@contact, @aspect)
            end
        end
    end
end