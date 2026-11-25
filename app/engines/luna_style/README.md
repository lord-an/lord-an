# LunaStyle

LunaStyle is the local, mountable engine that owns the Lord An storefront's
active theme setting and CSS design tokens. The host app mounts it at
`/luna-style`; administrators can change the active theme at
`/luna-style/theme`.

## Themes

The engine supports `classic`, `forest`, and `sunrise`. The `classic` theme is
the default. The current theme is persisted in the host application's
`luna_style_theme_settings` table and applied across the host and mounted
engines through the `data-luna-style-theme` body attribute. Store also retains
its `data-storefront-theme` attribute for compatibility.

## Host application setup

The host application's Gemfile includes this engine as a local path dependency.
Store declares LunaStyle as a dependency because it consumes the engine's
theme helper and stylesheet. The host mounts the engine in `config/routes.rb`;
the engine registers its helper for every Rails controller view, and each
standalone HTML layout loads the shared stylesheet.

Install the engine migration and migrate the host database:

```sh
bin/rails luna_style:install:migrations
bin/rails db:migrate
```

Only authenticated administrators can view or update the theme setting.
Authentication and administrator identity continue to be owned by the host
application and its `authenticate` engine.

## Tests

Run the host integration tests from the application root:

```sh
bin/rails test test/models/luna_style/theme_setting_test.rb
bin/rails test test/integration/luna_style_test.rb
```

Run the engine's isolated test suite from this directory:

```sh
bin/rails test
```
