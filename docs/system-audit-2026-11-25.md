# System Audit — 2026-11-25

## Executive summary

The Rails 8.1.4.1 host application has a clear mountable-engine architecture, and its tests, autoload check, and Brakeman scan pass. Authentication and administrator checks have integration coverage. Commerce is intentionally limited to unpaid orders, as documented.

The application is not ready for public production use as currently configured. Priorities are to establish whether existing databases contain legacy Store accounts that need migration, configure real production TLS and email delivery, strengthen the password policy, and make unsubscribe require an explicit state-changing action. CI's RuboCop job currently fails.

## Findings

### Confirmed

#### High — Production configuration remains template-level

- **Evidence:** TLS proxy and `force_ssl` settings are commented out in `config/environments/production.rb`; Action Mailer uses `example.com` and SMTP is unconfigured there. `config/deploy.yml` still specifies `192.168.0.1` and `localhost:5555`.
- **Impact:** Production deployment, HTTPS enforcement, and email delivery are not configured or verified for a real environment.
- **Next step:** Configure a real host and image registry, the TLS/proxy setup, and production mail delivery. Verify secure cookies and mail flows before launch.

#### Medium — One-character passwords are accepted

- **Evidence:** `app/models/user.rb` uses `has_secure_password` without a minimum-length validation. A non-persisting test-environment check confirmed a one-character password is valid.
- **Impact:** Accounts can be created with very weak credentials.
- **Next step:** Define a password minimum at the model boundary and test registration and password reset behavior.

#### Medium — Unsubscribe deletes a record on GET

- **Evidence:** `app/engines/store/config/routes.rb` exposes only `show` for unsubscribe. `Store::UnsubscribesController#show` destroys the subscriber, and `app/engines/store/test/integration/navigation_test.rb` verifies deletion after GET.
- **Impact:** Email link scanners or previews that fetch the link can unsubscribe the recipient unintentionally.
- **Next step:** Make GET show a confirmation page and require POST (or another state-changing verb) to unsubscribe. Update the mail template and tests.

#### Low — CI lint currently fails

- **Evidence:** `bin/rubocop -f simple` found 39 offenses: a missing final newline in `Gemfile` and spacing offenses in generated dummy schema files. `.github/workflows/ci.yml` runs RuboCop in CI.
- **Impact:** CI's lint job can fail despite a passing application test suite.
- **Next step:** Format these files or narrowly exclude generated schemas if that matches project policy.

### Risks and open questions

#### High — Possible legacy account migration gap

- **Evidence:** Historical migrations create `store_users` and `store_sessions` (`db/migrate/20261124235620_create_store_users.store.rb`, `db/migrate/20261124235621_create_store_sessions.store.rb`), while current authentication uses separately created host `users` and `sessions` tables (`db/migrate/20261125013248_create_users.rb`). No transfer migration was found. The current schema still contains both Store-era tables.
- **Impact:** If any deployed database contains accounts in the legacy tables, those users may not be able to sign in through the current host authentication system.
- **Next step:** Determine whether existing databases contain legacy accounts before deploying further migrations. If they do, plan and test an idempotent transfer. Database contents were not inspected during this audit.

#### Risk to confirm — Public wishlist visibility

- **Evidence:** `Store::WishlistsController#show` allows unauthenticated access and finds a wishlist by ID. The show view provides a copy-link action, suggesting public sharing may be intentional.
- **Impact:** Confirm whether public visibility and numeric IDs meet the intended privacy expectations.
- **Next step:** Document the intended sharing model and adjust visibility or identifiers only if product requirements call for it.

## Development roadmap

### Now

1. **Implemented locally:** the development database had one legacy account with no host-account match and no associated reviews or wishlists. A migration now copies such accounts and preserves password digests. Session cookies are versioned so old session IDs cannot resolve against new host sessions. Production databases still need a read-only account/dependent-record inventory and a reviewed rollout before migration.
2. **Configuration implemented; operator values required:** production now requires public host, registry and SMTP environment values, enables the Kamal TLS proxy and forces HTTPS. Select and supply actual deployment and mail-provider values before release.
3. **Implemented:** passwords require at least 12 characters in the shared user model, with signup/reset hints and validation tests.
4. **Implemented:** unsubscribe links now open a confirmation page; deletion requires an explicit DELETE form submission.

### Next

1. Resolve the 39 RuboCop offenses so the existing CI lint job can pass.
2. Confirm and document wishlist-sharing visibility.

### Later

1. Keep checkout disabled for live commerce until payment, inventory reservation, and order lifecycle behavior are implemented. The README already documents these limitations.
2. Consider pagination as the catalog grows; `Store::ProductsController#index` currently loads all products.

## Validation

- `bin/rails test` — passed after the roadmap changes: 62 tests, 418 assertions.
- Focused password, session, legacy-account, unsubscribe, and Portal integration tests — passed.
- `bin/rails zeitwerk:check` — passed.
- `bin/brakeman --no-pager` — passed with 0 security warnings.
- Changed Ruby implementation files pass RuboCop; the full repository run still reports 39 existing formatting offenses in `Gemfile` and generated dummy schemas.
- `git diff --check` — passed.
- `bin/rails test:system` — not verified: Chrome was unavailable and Selenium Manager could not download it because network DNS resolution failed. An offline Firefox retry also failed because the installed Snap wrapper was not recognized as a Firefox executable.
- Dependency and JavaScript vulnerability audits were not run; they may require network access.
- Deployment was not attempted. The local development database was inspected and migrated, but production databases and their dependent records still need a read-only inventory before rollout.

The initial audit was read-only. Subsequent roadmap work changed application code and migrated the local development database; no production database was accessed.
