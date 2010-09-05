class Devise::InvitationsController < ApplicationController
  include Devise::Controllers::InternalHelpers
  include DeviseInvitable::Controllers::Helpers
  
  before_filter :authenticate_inviter!, :only => [:new, :create]
  before_filter :has_invitations_left, :only => [:create]
  before_filter :require_no_authentication, :only => [:edit, :update]
  helper_method :after_sign_in_path_for

protected

  def has_invitations_left
    current_user.invitation_count > 0
  end
public
  
  # GET /resources/invitation/new
  def new
    build_resource
    render_with_scope :new
  end
  
  # POST /resources/invitation
  def create
    self.resource = resource_class.invite(params[resource_name])
    
    if resource.invited?
      if resource_class.invitation_limit.present?
        if resource.invitation_count.nil?
          current_user.update_attributes({:invitation_count => resource_class.invitation_limit-1})
        else
          current_user.update_attributes({:invitation_count => current_user.invitation_count-1})
        end
      end
      set_flash_message(:notice, :send_instructions, :email => params[resource_name][:email])
      redirect_to after_sign_in_path_for(resource_name)
    else
      render_with_scope :new
    end
  end
  
  # GET /resources/invitation/accept?invitation_token=abcdef
  def edit
    self.resource = resource_class.find_or_initialize_with_error_by(:invitation_token, params[:invitation_token])
    render_with_scope :edit
  end
  
  # PUT /resources/invitation
  def update
    self.resource = resource_class.accept_invitation(params[resource_name])
    
    if resource.errors.empty?
      set_flash_message(:notice, :updated)
      sign_in_and_redirect(resource_name, resource)
    else
      render_with_scope :edit
    end
  end
  
end
