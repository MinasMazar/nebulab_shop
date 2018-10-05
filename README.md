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
