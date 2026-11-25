# Commerce engine

The mountable `Commerce` engine owns authenticated customer carts and order
snapshots. It depends on the host account/session contract, the Store product
catalog, and the shared Internationalization engine.

Routes are mounted at `/commerce`. The current checkout creates an
`pending_payment` order and snapshots product names and prices. It does not
charge customers, reserve inventory, calculate tax or shipping, or confirm
payment. Do not treat these records as paid orders or enable this as a live
checkout until a payment provider, currency/region rules, and stock reservation
policy have been selected and implemented.
