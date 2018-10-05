# Forces all threads to share the same connection. This works on
# Capybara because it starts the web server in a thread.
class ActiveRecord::Base
  mattr_accessor :shared_connection
  @@shared_connection = nil

  def self.connection
    @@shared_connection || retrieve_connection
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    # Use transactions for tests
    DatabaseCleaner.strategy = :transaction
    Apartment::Tenant.drop('pescara_shop') rescue nil
    Apartment::Tenant.create('pescara_shop')
  end

  config.before(:each) do
    # Start transaction for this test
    DatabaseCleaner.start
    Capybara.run_server = false
    ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection
    Apartment::Tenant.drop('pescara_shop') rescue nil
    # Create the default tenant for our tests
    Apartment::Tenant.create('pescara_shop')
  end

  config.before(:each, type: :feature) do
    ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection
    Apartment::Tenant.switch!('pescara_shop')
  end

  config.after(:each) do
    # Reset tenant back to `public`
    Apartment::Tenant.reset rescue nil
    # Rollback transaction
    DatabaseCleaner.clean
  end

  config.after(:each, type: :feature) do
    DatabaseCleaner.strategy = :truncation if Capybara.current_driver != :rack_test
    ActiveRecord::Base.shared_connection = nil
  end

  config.before(:example, type: :integration) do |example|
    host! extract_host_from_example(example)
  end

  config.before(:example, type: :request) do |example|
    host! extract_host_from_example(example)
  end

  config.before(:example, type: :controller) do |example|
    controller.request.host = extract_host_from_example(example)
  end

  config.before(:example, type: :view) do |example|
    @request.host = extract_host_from_example(example)
  end

  config.before(:example, type: :feature) do |example|
    domain = extract_host_from_example(example)
    Capybara.app_host = "http://#{domain}"
  end

  def extract_host_from_example(example)
    tenant = example.metadata[:tenant] || "pescara_shop"
    act_tenant = Apartment::Tenant.current
    NebulabShop::Stores[tenant.to_sym]
  end
end
