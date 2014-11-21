require 'spec_helper'

describe StripeWrapper::Charge do 
  before do 
    StripeWrapper.set_api_key
  end

  let(:valid_token) do
    Stripe::Token.create(
      :card => {
        :number => '4242424242424242',
        :exp_month => 3,
        :exp_year => Time.new.year + 1, # keeps the credit card year valid
        :cvc => 123
      }
    ).id
  end

  let(:declined_card_token) do
    Stripe::Token.create(
      :card => {
        :number => "4000000000000002",
        :exp_month => 3,
        :exp_year => Time.new.year + 1, # keeps the credit card year valid
        :cvc => 123
      }
    ).id
  end

  context "with valid card" do 
    let(:card_number) { '4242424242424242' }

    it "charges the card successfully" do
      response = VCR.use_cassette 'Stripe Charge' do
        StripeWrapper::Charge.create(amount: 300, card: valid_token)
      end
      response.should be_successful
    end
  end
  context "with invalid card" do 
    let(:card_number) { '4000000000000002' }
    let(:response) do
      VCR.use_cassette('Stripe Invalid Card') do 
        StripeWrapper::Charge.create(amount: 300, card: valid_token)
      end
    end

    it "does not charge the card successfully" do
      response.should_not be_successful
    end
  end
  describe StripeWrapper::Customer do 
    describe ".create" do 
      it "creates a customer with valid card" do
        karen = Fabricate(:user)
        response = VCR.use_cassette('Stripe create customer subscription') do 
            StripeWrapper::Customer.create(
              user: karen,
              card: valid_token
            )
        end
        expect(response).to be_successful
      end
      it "does not create a customer with declined card"
    end
  end
end


