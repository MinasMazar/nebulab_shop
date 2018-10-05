require 'rails_helper'

RSpec.feature Spree::Preferences, type: :feature do
  TENANTS_EXPECTATIONS = {
    latina_shop: {
      mails_from: 'store@latina-shop.com',
      locale: :en
    },
    pescara_shop: {
      mails_from: 'store@pescara-shop.com',
      locale: :it
    }
  }

  NebulabShop::Stores.each do |tenant, domain|

    describe "when visiting #{tenant}", tenant: tenant do
      let(:mails_from) { tenant_expectation_for(tenant, :mails_from) }
      let(:locale) { tenant_expectation_for(tenant, :locale) }

      before do
        Capybara.app_host = "http://#{domain}"
        visit spree.products_path
      end

      it "sets the correct tenant" do
        expect(Apartment::Tenant.current).to eq(tenant)
      end

      it "sets the correct locale" do
        expect(I18n.locale).to eq(locale)
      end

      it 'fetch Solidus preferences from the correct tenant' do
        expect(page).to have_css("li#mails-from.testing", text: "Contact us at #{mails_from}")
      end
    end

  end

  private

  def tenant_expectation_for(tenant, key)
    TENANTS_EXPECTATIONS[tenant][key.to_sym]
  end
end
