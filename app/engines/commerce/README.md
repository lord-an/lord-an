# Commerce engine

The mountable `Commerce` engine owns authenticated customer carts and order
snapshots. It depends on the host account/session contract, the Store product
catalog, and the shared Internationalization engine.

Routes are mounted at `/commerce`. Checkout reserves inventory, calculates
destination tax with AvaTax, charges shipping at USD 100.00/kg using the
administrator-maintained product weight, and redirects to Adyen Hosted
Checkout. Products need both a positive shipping weight and an AvaTax product
tax code before they are purchasable. An order becomes `paid` only after a
valid, amount-matched Adyen authorization webhook and AvaTax commit. Orders in any other state must not be
fulfilled. Checkout currently accepts USD only, and actual country support
depends on the merchant's provider accounts and tax coverage.

Production requires live Adyen and AvaTax credentials plus the merchant
ship-from address; see the root README for the full environment-variable and
operational checklist. Local tests use provider stubs; live transactions,
webhook delivery, tax compliance, and disaster-recovery restoration still
require operator verification before launch.

Administrators can review paid orders and mark them fulfilled after external
shipment. Carrier labels, tracking notifications, refunds, and automatic
fulfillment are not implemented.
