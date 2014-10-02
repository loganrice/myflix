require 'spec_helper'

describe UsersController do
  describe "GET new" do
    it "should create @user variable" do
      get :new
      assigns(:user).should be_instance_of(User)
    end
  end

  describe "GET show" do
    it_behaves_like "require_sign_in" do 
      let(:action) { get :show, id: 3 }
    end

    it "sets @user" do 
      set_current_user
      karen = Fabricate(:user)
      get :show, id: karen.id
      assigns(:user).should == karen
    end
   
  end

  describe "POST create" do
    context "successful user sign up" do 
      it "redirects to sign in path" do
        result = double(:sign_ub_result, successful?: true)
        UserSignup.any_instance.should_receive(:sign_up).and_return(result)
        post :create, user: Fabricate.attributes_for(:user)
        response.should redirect_to sign_in_path
      end
    end
    context "failed user sign up" do 
      it "renders the new template" do 
        result = double(:sign_ub_result, successful?: false)
        UserSignup.any_instance.should_receive(:sign_up).and_return(result)
        post :create, user: Fabricate.attributes_for(:user), stripeToken: '1234'
        response.should render_template :new
      end
      it "sets the flash error message" do 
        result = double(:sign_ub_result, successful?: false, error_message: "This is an error message.")
        UserSignup.any_instance.should_receive(:sign_up).and_return(result)
        post :create, user: Fabricate.attributes_for(:user), stripeToken: '1234'
        flash[:error].should == "This is an error message."
      end
    end
  end

  describe "GET new_with_invitation_token" do
    it "renders the :new view template" do

      invitation = Fabricate(:invitation)
      get :new_with_invitation_token, token: invitation.token 
      response.should render_template :new      
    end
    it "sets @user with recipient's email" do
      invitation = Fabricate(:invitation)
      get :new_with_invitation_token, token: invitation.token 
      assigns(:user).email.should == invitation.recipient_email
    end 
    it "redirects to expired token page for invalid tokens" do 
      get :new_with_invitation_token, token: 'asdfasdf'
      response.should redirect_to expired_token_path
    end

    it "sets @invitation_token" do
      invitation = Fabricate(:invitation)
      get :new_with_invitation_token, token: invitation.token 
      assigns(:invitation_token).should == invitation.token
    end
  end
end