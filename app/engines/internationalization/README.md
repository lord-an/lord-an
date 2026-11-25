# Internationalization engine

This engine configures Rails I18n for English, French, and Spanish across the
host application and mounted engines. It provides locale dictionaries,
pluralization rules, date/time formats, a language settings page, and a locale
preference endpoint, following the [Rails Internationalization guide](https://guides.rubyonrails.org/i18n.html).

Signed-in users store their language in `User#preferred_locale`. Guests store
their choice in an HTTP-only cookie. Locale switching is scoped to each request
with `I18n.with_locale`.

Mount at `/internationalization`. Application controllers include
`Internationalization::Locale` so locale selection is consistent across the
host and each engine.

Product names and rich-text descriptions are translated separately in
`Store::ProductTranslation` records, since database content is not managed by
Rails' YAML locale dictionaries.
