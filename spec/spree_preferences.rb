require 'rails_helper'

Spree::Config.configure do |config|
  config.mails_from = "store@test-shop.com"
  config.currency = "EUR"
end

Spree::Frontend::Config.configure do |config|
  config.locale = :it
end

RSpec.feature Spree::Preferences, type: :model do
  describe "when visiting test_tenant" do
    it 'fetch Solidus preferences from the correct tenant' do
      expect(Spree::Config[:mails_from]).to eql("store@test-shop.com")
      expect(Spree::Config[:currency]).to eql("EUR")
      expect(Spree::Frontend::Config[:locale]).to eql("it")
    end
  end
end
