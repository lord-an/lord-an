# Store engine

This mountable Rails engine implements the product store from the
[Rails Getting Started guide](https://guides.rubyonrails.org/getting_started.html).
It provides product management, inventory, rich-text descriptions, image
uploads, subscriber notifications, and shared host authentication.
Customers signed in through the host `authenticate` engine can create and
manage wishlists, add products from their product pages, move or remove
products, and share a public wishlist URL. The wishlist behavior follows the
[Rails Wishlists guide](https://guides.rubyonrails.org/wishlists.html).
Signed-in customers can also rate and review products, attach images, and filter
reviews by rating. Product pages display the average rating and rating breakdown
using behavior from the [Rails Product Reviews guide](https://edgeguides.rubyonrails.org/product_reviews.html).
Only accounts explicitly granted the host application's `admin` flag can
create, update, or delete products. Customers can browse products, review them,
and manage wishlists.

## Mounting

Add the engine to the host application's Gemfile:

```ruby
gem "store", path: "app/engines/store"
```

Mount it at `/store`:

```ruby
mount Store::Engine => "/store"
```

Install the engine and Rails Action Text/Active Storage migrations in the host
application, then migrate:

```sh
bundle exec rake store:install:migrations
bin/rails action_text:install
bin/rails db:migrate
```

Wishlists belong to host `User` records and use the installed Store migrations.
They are available under `/store/wishlists`; public wishlist pages can be shared
without exposing the owner’s other lists.

The store is available at `/store`. Product listings and details are public.
Catalog management requires an administrator account. New accounts are not
administrators. To promote an existing operator account, use the host
application's Rails console:

```ruby
User.find_by!(email_address: "operator@example.org").update!(admin: true)
```

Products store price in integer minor units and an explicit three-letter
currency code. Legacy products without a configured positive price are
displayed as unavailable for purchase.

The host application's separate `Commerce` engine mounts at `/commerce` and
uses Store products to populate customer carts and unpaid order snapshots.

Run the engine test suite from the engine directory:

```sh
bin/rails db:migrate
bin/rails test
```
