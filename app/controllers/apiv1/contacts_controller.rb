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
          
        render :json =>{
            :contacts=> @response
        }
    end
    
    def create
        @person = Person.find(params[:id])
        @aspect = theAspect()

      	if @contact = @user.share_with(@person, @aspect)
      	  flash.now[:notice] =  I18n.t 'aspects.add_to_aspect.success'
      	  respond_with AspectMembership.where(:contact_id => @contact.id, :aspect_id => @aspect.id).first
      	else
      	  flash[:error] = I18n.t 'contacts.create.failure'
      	  #TODO(dan) take this out once the .js template is removed
      	  render :nothing => true
      	end
    end
end