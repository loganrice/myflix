require 'spec_helper'

describe UserSignup do 
  describe "#sign_up" do 
    context "valid personal info and valid card" do 
      let(:charge) { double(:charge, succesful?: true) }
      before do 
        StripeWrapper::Charge.should_receive(:create).and_return(charge)
      end
      around(:each) { ActionMailer::Base.deliveries.clear } 

      it "creates a user" do 
        UserSignup.new(Fabricate.build(:user)).sign_up("some_stripe_token", nil)
        User.count.should == 1
      end

      it "makes the user follow the inviter" do
        karen = Fabricate(:user)
        invitation = Fabricate(:invitation, inviter: karen, recipient_email: "karen@example.com")
        UserSignup.new(Fabricate.build(:user, email: 'joe@example.com', password: 'password', full_name: 'Joe brown')).sign_up("some_stripe_token", invitation.token) 
        joe = User.find_by(email: 'joe@example.com')
        karen.follows?(joe).should be_true
      end

      it "makes the inviter follow the user" do
        karen = Fabricate(:user)
        invitation = Fabricate(:invitation, inviter: karen, recipient_email: "karen@example.com")
        UserSignup.new(Fabricate.build(:user, email: 'joe@example.com', password: 'password', full_name: 'Joe brown')).sign_up("some_stripe_token", invitation.token) 
        joe = User.find_by(email: 'joe@example.com')
        joe.follows?(karen).should be_true
      end

      it "expires the invitation upon acceptance" do
        karen = Fabricate(:user)
        invitation = Fabricate(:invitation, inviter: karen, recipient_email: "karen@example.com")
        UserSignup.new(Fabricate.build(:user, email: 'joe@example.com', password: 'password', full_name: 'Joe brown')).sign_up("some_stripe_token", invitation.token) 
        Invitation.first.token.should be_nil
      end

      it "sends out the email" do
        karen = { email: "karen@example.com", password: "password", full_name: "Karen Example" }
        UserSignup.new(Fabricate.build(:user, email: 'joe@example.com')).sign_up("some_stripe_token", nil) 
        ActionMailer::Base.deliveries.should_not be_nil
      end
      it "sends it to the right person" do
        karen = { email: "karen@example.com", password: "password", full_name: "Karen Example" }
        UserSignup.new(Fabricate.build(:user, email: 'joe@example.com')).sign_up("some_stripe_token", nil) 
        message = ActionMailer::Base.deliveries.last
        message.to.should == [karen["email"]]
      end
      it "has the right content" do
        karen = { email: "karen@example.com", password: "password", full_name: "Karen Example" }
        UserSignup.new(Fabricate.build(:user, email: 'joe@example.com')).sign_up("some_stripe_token", nil) 
        message = ActionMailer::Base.deliveries.last
        message.body.should include(karen["full_name"])
      end
      it "does not send email if input is invalid" do
        karen = { email: "karen@example.com"}
        UserSignup.new(Fabricate.build(:user, email: 'joe@example.com')).sign_up("some_stripe_token", nil) 
        ActionMailer::Base.deliveries.should be_empty
      end
    end
    context "valid personal info and declined card" do 
      it "does not create a user" do
        charge = double(:charge, successful?: false, error_message: "Your card was declined.")
        StripeWrapper::Charge.should_receive(:create).and_return(charge)
        UserSignup.new(Fabricate.build(:user)).sign_up("1344", nil)         
        User.count.should == 0
      end
    end

    context "with invalid personal info" do
      it "does not charge the card" do
        StripeWrapper::Charge.should_not_receive(:create)
        UserSignup.new(User.new(email: "bob@example.com")).sign_up('123', nil)   
      end
      it "does not create the user" do
        UserSignup.new(User.new(email: "bob@example.com")).sign_up('123', nil)  
        User.count.should == 0
      end
    end
  end
end