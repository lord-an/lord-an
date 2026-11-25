# Lord An

A Rails 8.1.4.1 application built from a host app and mountable engines. The
current product is a localized product catalog with account authentication,
wishlists, reviews, and inventory notifications.

## Requirements

- Ruby 4.0.10
- SQLite 3
- The native dependencies required by Rails and Active Storage image processing

## Development

```sh
bin/setup
bin/rails db:prepare
bin/rails server
```

The application overview is available at `/`; the storefront is available at
`/store`. Sign-up and login are under
`/authenticate`; account settings are under `/portal`; customer carts and unpaid
order records are under `/commerce`. Run the application test suite with:

```sh
bin/rails test
bin/rails test:system
```

The application supports English, French, and Spanish. Guests select a locale
that is stored in a cookie; signed-in users can save a preferred locale in
account settings.

## Store administration

New accounts are customers by default. To grant catalog-management access to an
existing account, use the Rails console as a trusted operator:

```ruby
User.find_by!(email_address: "operator@example.com").update!(admin: true)
```

Only administrators can create, update, or delete products. Customers and guests
can browse the catalog.

## Engine boundaries

- `Authenticate` owns sign-up, sessions, and password reset, using the host
  application's account and session models.
- `Portal` owns signed-in account settings.
- `LunaStyle` owns shared design tokens and theme selection across the host
  application and all mounted engines.
- `Store` owns catalog, inventory, product reviews, wishlists, and stock alerts.
- `Commerce` owns customer carts and order snapshots, depending on Store through
  its product model.
- `Internationalization` owns locale selection and dictionaries shared by the
  host and mounted engines.

The Commerce engine currently creates `pending_payment` orders only. It does
not charge customers, reserve inventory, or calculate tax or shipping. Do not
enable it as a live checkout until a payment provider, currency/region rules,
and stock-reservation policy have been selected and implemented behind a
provider adapter.

## Production readiness

Deployment configuration in `config/deploy.yml` still contains example host
and registry values. Configure a real host, registry, Rails master key, HTTPS,
and Action Mailer delivery before deployment. Production currently stores the
SQLite database and Active Storage uploads on the local persistent volume;
backups and restores must include both. This single-host setup should be
revisited before horizontal scaling or availability guarantees.

## Near-term roadmap

1. Establish a secure operator/admin provisioning and recovery process.
2. Select currency/region rules, payment and fulfillment providers, then
   complete provider callbacks, stock reservation, tax, shipping, and order
   cancellation in the Commerce engine.
3. Configure and verify production email, background-job retries, and
   unsubscribe handling.
4. Validate deployment, HTTPS, database/upload backups, and restoration.
5. Prioritize storefront search, categories, pagination, and accessibility
   based on customer needs.
