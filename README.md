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
`/authenticate`; account settings are under `/portal`; customer carts and orders
are under `/commerce`. Run the application test suite with:

```sh
bin/rails test
bin/rails test:system
```

The application supports English, French, and Spanish. Guests select a locale
that is stored in a cookie; signed-in users can save a preferred locale in
the unified Settings page.

## Store administration

New accounts are customers by default. To grant catalog-management access to an
existing account, use the Rails console as a trusted site owner:

```ruby
User.find_by!(email_address: "operator@example.com").update!(admin: true)
```

Only administrators can create, update, or delete products. Customers and guests
can browse the catalog. The same `admin: true` flag grants access to storefront
appearance controls. No administrator is provisioned automatically; a trusted
site owner must explicitly promote the intended account. There is no in-app
administrator-management screen.

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

Commerce uses Adyen Hosted Checkout and only marks an order paid after a valid,
amount-matched Adyen `AUTHORISATION` webhook. Inventory is reserved when a
checkout session is created and released after refusal or expiry. AvaTax
calculates destination tax, and shipping is charged at USD 100.00 per kilogram
using administrator-maintained product weights. Checkout currently accepts USD
only; destination support depends on the configured Adyen merchant account and
AvaTax coverage. Orders requiring payment or tax reconciliation are not
fulfillable until their status is `paid`.

## Production readiness

Before deploying, set `KAMAL_HOST`, `KAMAL_IMAGE`, `KAMAL_REGISTRY_SERVER`,
`KAMAL_REGISTRY_USERNAME`, and `APP_HOST` in the deployment environment.
`APP_HOST` must be the public DNS hostname used by the HTTPS proxy. Provide
`RAILS_MASTER_KEY`, `KAMAL_REGISTRY_PASSWORD`, `SMTP_USERNAME`,
`SMTP_PASSWORD`, `ADYEN_API_KEY`, `ADYEN_HMAC_KEY`, `AVATAX_ACCOUNT_ID`, and
`AVATAX_LICENSE_KEY` through Kamal's secrets. Set `SMTP_ADDRESS` and optionally
`SMTP_PORT`, `SMTP_DOMAIN`, and `SMTP_AUTHENTICATION` in the deployment
environment. Also configure `ADYEN_ENVIRONMENT=live`, `ADYEN_MERCHANT_ACCOUNT`,
`ADYEN_LIVE_PREFIX`, `AVATAX_ENVIRONMENT=production`, `AVATAX_COMPANY_CODE`,
and the `MERCHANT_ORIGIN_*` address values. Production refuses to boot unless
these provider credentials and merchant-origin fields are present and valid;
never use production credentials in local development or tests. Configure the
Adyen Standard webhook to `https://APP_HOST/commerce/webhooks/adyen` and enable
HMAC signing with the configured key.

Production uses Kamal's TLS proxy, forces HTTPS, sends mail through SMTP with
STARTTLS, and runs Solid Queue with Puma. Product weights must be populated
before items are purchasable; products without a positive weight or a valid
AvaTax product tax code are rejected at checkout. The shipping amount is weight
in grams × 10 cents, which is exactly USD 100.00/kg; AvaTax receives a separate
freight line. Assign the correct tax code to each product and review merchant
nexus/settings with Avalara before accepting sales. Provider coverage and
merchant-account country restrictions can limit destinations even though the
checkout accepts ISO country codes.

Production stores SQLite databases and Active Storage uploads on a local
persistent volume. Backups must be coordinated and include the primary database
and uploads; rehearse a restore before launch. The repository has no production
host, provider credentials, or deploy environment, so live payment, tax, email,
webhook delivery, and backup restoration have not been exercised here. Complete
a sandbox purchase/refusal/expiry cycle and an operator-controlled restore
rehearsal before switching the configured providers to live credentials.

Administrators can review orders and shipping addresses under `/commerce/orders`
and mark a paid order fulfilled after arranging shipment. Carrier labels,
tracking notifications, refunds, and fulfillment automation are not integrated;
those steps remain manual and require an operator procedure.

The migration `20261125181000_migrate_legacy_store_users_to_host_users` copies
legacy Store accounts without a host account, preserving their password
digests. Existing sessions are intentionally not migrated; the host uses a new
session-cookie name, so existing users must sign in again. Keep the legacy
tables until production account and dependent-record migration has been
verified.

## Near-term roadmap

1. Establish a secure operator/admin provisioning and recovery process.
2. Verify the Adyen/AvaTax integrations with merchant sandbox accounts and
   complete the country-specific tax, product tax-code, and shipping review.
3. Configure and verify production email, background-job retries, and
   unsubscribe handling.
4. Validate deployment, HTTPS, database/upload backups, and restoration.
5. Prioritize storefront search, categories, pagination, and accessibility
   based on customer needs.
