require 'test_helper'

class MultitenantPreferencesTest < ActionDispatch::IntegrationTest
  TENANTS_EXPECTATIONS = {
    latina_shop: {
      mails_from: 'store@latina-shop.com',
      locale: 'en'
    },
    pescara_shop: {
      mails_from: 'store@pescara-shop.com',
      locale: 'it'
    }
  }

  NebulabShop::Stores.each do |tenant, domain|
    test "#{tenant}" do
      host! domain
      get '/'
      assert_response :success
      assert_select '#mails-from.testing', "Mails from: #{TENANTS_EXPECTATIONS[tenant][:mails_from]}"
      assert_select '#locale.testing', "Locale: #{TENANTS_EXPECTATIONS[tenant][:locale]}"
    end
  end
end
