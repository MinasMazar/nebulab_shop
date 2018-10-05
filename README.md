# NebulabShop

NebulabShop is a simple e-commerce based on [Solidus](solidus-gh) with
tutorial-purpose in which I'll show how to migrate a Solidus application from
single to multitenant.

# Install and setup Solidus gem

Init new Rails application with PostgreSQL.

```sh
$ rails new nebulab_shop --database=postgresql
```
    
Add 'solidus' and 'solidus_auth_devise' to Gemfile

```ruby
gem 'solidus', '~> 2.6'
gem 'solidus_auth_devise', '~> 2.1.0'
```

then launch:

```sh
$ bundle exec rails g spree:install
$ bundle exec rails g solidus:auth:install
$ bundle exec rake railties:install:migrations
$ bundle exec rake spree_sample:load
```

# Install and setup Apartment

Add Apartment gem to the project dependencies

```ruby
gem 'apartment', '~> 2.2.0'
```

and then launch the command

```sh
bundle exec rails generate apartment:install
```

This will create the Apartment init file at `config/initializers/apartment.rb`.
Among the whole well-documented settings, you can tell apartment which
_Elevator_ to use (i.e. the criteria for tenant switching). There are a bunch of
built-in elevators in `Apartmen::Elevators` module: Generic, Domain, Subdomain,
FirstSubdomain, Host, HostHash, but you can also define your own custom elevator.

In our example we use the `HostHash` elevator which establish an hard-coded association from a
domain name to a tenant, so if we get a request to 'http://pescara-shop.com' the
apartment gem will switch to `pescara_shop` tenant.

```ruby
NebulabShop::Stores = {
  pescara_shop: 'pescara-shop.com',
  latina_shop: 'latina-shop.com'
}
```

Now we have to create our tenants

```sh
bin/rake apartment:create
```

You can verify that new schemas were actually created in your database as follow

```sh
psql nebulab_shop_development -c "\dn"

    List of schemas
     Name     |  Owner
--------------|---------
 latina_shop  | seller
 pescara_shop | seller
 public       | seller
(3 rows)
```

# Testing with RSpec

Since Solidus uses [RSpec][rspec-homepage], I'have focused my analysis on how this testing suite works with Apartment gem. Let's begin taking a look at this [Apartment wiki page][apartment-testing]. Here we can find most of instructions and best practices we need:

```
The number one thing that has helped us in testing is to create a single tenant before the whole test suite runs and switch to that tenant for the run of your tests.
```

In fact, testing with feature (JS) specs it's quite a mess.. If I'm not wrong, the reason is the same why we could not use __transactional tests_ with Capybara:

> Transactional fixtures do not work with Selenium tests, because Capybara uses a separate server thread, which the transactions would be hidden from. We hence use DatabaseCleaner to truncate our test database.

See [here][apartment-capybara-issue444] for more details.

```
Capybara does it's stuff in a separate thread to the main test thread. due to connection sharing in rails 5.1, both threads use the same database connection. apartment instantiates a different adapter object per thread, and the capybara adapter doesn't receive the switch! issued during test bootstrapping, so as far as it's concerned the "current" tenant is still the default_tenant 'public' (despite the main test thread, and main test apartment adapter, changing the "schema_search_path" for the shared connection).
```

The combination of the mandatory use of [DatabaseCleaner][dbcleaner-gh] and the need of testing against a single test-tenant, produce a quite standard configuration like this:

```ruby
# spec/rails_helper.rb

config.use_transactional_fixtures = true

RSpec.configure do |config|
  config.before(:suite) do
    # Clean all tables to start
    DatabaseCleaner.clean_with :truncation
    # Use transactions for tests
    DatabaseCleaner.strategy = :transaction
    # Truncating doesn't drop schemas, ensure we're clean here, app *may not* exist
    Apartment::Tenant.drop('test_app') rescue nil
    # Create the default tenant for our tests
    Apartment::Tenant.create('test_app')
  end

  config.before(:each) do
    # Start transaction for this test
    DatabaseCleaner.start
    # Switch into the default tenant
    Apartment::Tenant.switch! 'test_app'
  end

  config.after(:each) do
    # Reset tentant back to `public`
    Apartment::Tenant.reset
    # Rollback transaction
    DatabaseCleaner.clean
  end
end
```

Here a little sum up on how to set host in request spec

```ruby
# Integration Specs (inheriting from ActionDispatch::IntegrationTest):

host! "my.awesome.host"

# Controller Specs (inheriting from ActionController::TestCase)

@request.host = 'my.awesome.host'

# View Specs (inheriting from ActionView::TestCase)

@request.host = 'my.awesome.host'

# ...or through RSpec:

controller.request.host = "my.awesome.host"
```

