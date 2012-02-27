class Apiv1::ContactsController < Apiv1::BaseController
  
    # GET all contacts within a specific aspect for the current user
    def index
        @contacts = theAspect.contacts
        @response = Hash.new
        @response=[]
        @contacts.each do |contact|
            profile= contact.person.profile
            @profiletags = Array.new
            profile.tags.each do |tag|
                @profiletags << tag.name
            end
            @response << profile.id 
        end
        #self id
        @response << @user.person.profile.id   
        render :json =>{
            :contacts=> @response
        }
    end
    
    def show
        @ids=params[:ids]
        @aspect = theAspect()
        
        @ids.each do |id|
            @person = Person.find(id)
            render :json=>{:user=>@user,:aspect=>@aspect, :person=>@person}
            #@contact = @user.share_with(@person, @aspect)
        end
    end
end