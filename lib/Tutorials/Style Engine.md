# A Skin for the Store: Build a Convention-Driven Style Engine

Add a local, mountable Rails engine that owns application-wide theme selection
and design tokens, then apply it to the host application and every mounted
engine using Rails conventions rather than a configurable theme framework.

## Table of Contents

- [1. What You Will Build](#1-what-you-will-build)
- [2. Prerequisites and Baseline](#2-prerequisites-and-baseline)
- [3. Trace the Existing Conventions](#3-trace-the-existing-conventions)
- [4. Generate and Mount the Engine](#4-generate-and-mount-the-engine)
- [5. Persist the Active Theme](#5-persist-the-active-theme)
- [6. Build the Protected Theme Setting](#6-build-the-protected-theme-setting)
- [7. Apply the Theme to the Storefront](#7-apply-the-theme-to-the-storefront)
- [8. Test the Complete Feature](#8-test-the-complete-feature)
- [9. What You Learned](#9-what-you-learned)
- [10. Acceptance Criteria](#10-acceptance-criteria)
- [11. Stretch Challenges](#11-stretch-challenges)
- [12. Official Rails References](#12-official-rails-references)

## 1. What You Will Build

Rails follows **convention over configuration**: when a class, file, and
directory follow Rails' naming rules, Rails can connect them without extra
configuration. This project will use those conventions for a mountable engine,
its routes, a setting model, a helper, and a stylesheet.

The application has one storefront and one active theme. This tutorial
intentionally does not add tenant-specific settings, arbitrary CSS editing, a
theme plugin registry, or a preview framework. Those features would require
additional requirements and configuration.

### Tutorial details

- **Difficulty:** Intermediate
- **Scope:** Mini-project
- **Target application:** Existing Lord An Rails application
- **Rails:** 8.1.4.1
- **Ruby:** 4.0.10
- **Primary concept:** Convention over configuration
- **Features practiced:** Mountable and isolated engines, local path gems, engine
  migrations, RESTful routes, Active Record validations, authentication and
  authorization, strong parameters, view helpers, Propshaft assets, and
  integration tests

### Learning objectives

By completing this tutorial, learners will be able to:

1. Explain how Rails engine names, namespaces, and conventional directories
   connect routes, controllers, models, helpers, views, and assets.
2. Add a local engine to a host application's dependency graph and mount its
   isolated routes.
3. Use an engine-owned migration and model to persist a constrained setting.
4. Protect a settings endpoint by reusing the host application's authentication
   mechanism and established administrator policy.
5. Connect engine-owned helper behavior and CSS assets to an existing engine
   without introducing a configurable theme registry.
6. Verify model rules, authorization, persistence, route behavior, and rendered
   theme selection with tests.

### Finished application

- The existing catalog remains at `/store`.
- A new `LunaStyle` engine is mounted at `/luna-style`.
- Administrators can view and change the active theme at
  `/luna-style/theme`.
- Every host and mounted-engine layout exposes the selected theme as a
  `data-luna-style-theme` attribute on `<body>`. Store retains its
  `data-storefront-theme` attribute for compatibility.
- Shared styles use design tokens with `classic`, `forest`, and `sunrise`
  palettes across the application.
- The default is `classic`; the selected value persists in the host database.

## 2. Prerequisites and Baseline

Use the existing application; do not generate or replace a host Rails app.
Confirm the project bundle uses Ruby 4.0.10 and Rails 8.1.4.1.

Before editing, inspect the current worktree and run the focused Store mount
test:

```sh
git status --short
bin/rails test test/integration/store_mount_test.rb
```

Keep existing user changes untouched. Record any pre-existing test failure so
it is not mistaken for a regression introduced by the tutorial.

Authentication, user records, and the `admin` flag already belong to the host
application. Do not add a second user model or an alternate login flow. This
feature requires no third-party service or credentials.

## 3. Trace the Existing Conventions

Before making changes, read the current worktree and inspect these files:

- `Gemfile` and `config/routes.rb`
- `app/engines/store/store.gemspec`
- `app/engines/store/lib/store/engine.rb`
- `app/engines/store/config/routes.rb`
- `app/engines/store/app/controllers/store/application_controller.rb`
- `app/engines/store/app/controllers/store/products_controller.rb`
- `app/engines/store/app/helpers/store/application_helper.rb`
- `app/engines/store/app/views/layouts/store/application.html.erb`
- `app/engines/store/app/assets/stylesheets/store/application.css`
- `app/engines/authenticate/app/controllers/authenticate/authentication.rb`
- `test/test_helper.rb`, `test/test_helpers/session_test_helper.rb`, and
  `test/integration/store_mount_test.rb`

The host app loads engines as local path gems under `app/engines`. Store is an
isolated engine and its controller includes `Authenticate::Authentication`.
Product administration uses `Current.user&.admin?` and redirects unauthorized
users to `/store`. Follow those established boundaries. Do not edit existing
work unrelated to this tutorial.

Confirm that Store is mounted at `/store`, unauthenticated access redirects to
`/authenticate/session/new`, and signed-in non-admin catalog management
requests redirect to `/store`. The tutorial reuses these established
conventions rather than creating new host-level configuration.

## 4. Generate and Mount the Engine

**Goal:** Let Rails' engine generator establish namespaced files and defaults.

**Generate the engine.** From the host application's root:

```sh
bin/rails plugin new app/engines/luna_style --mountable --skip-git
```

The `--mountable` option creates an isolated engine with its own routes and
namespaces. Inspect the generated files before changing them. Keep the
generated `LunaStyle` namespace and `isolate_namespace` declaration;
adapt the gemspec to this repository's local path-gem conventions and Rails
minimum version.

**Add the path dependency.** In the host `Gemfile`, alongside the existing
local engines:

```ruby
gem "luna_style", path: "app/engines/luna_style"
```

The new engine's settings controller will include the host authentication
concern, so declare that runtime dependency in
`app/engines/luna_style/luna_style.gemspec`:

```ruby
spec.add_dependency "authenticate", ">= 0.1.0"
```

For the engine's own development/test bundle, use the repository's local engine
paths in `app/engines/luna_style/Gemfile`. The authentication engine depends on
Internationalization, so declare both local gems:

```ruby
gem "authenticate", path: "../authenticate"
gem "internationalization", path: "../internationalization"
```

From `app/engines/luna_style`, run `bundle install` before using its `bin/rails`
commands. This lets the engine's standalone bundle resolve local dependencies
instead of looking for these application-specific engines on RubyGems.

Store will use the style engine's helper and model. Make that dependency
explicit in `app/engines/store/store.gemspec`:

```ruby
spec.add_dependency "luna_style", ">= 0.1.0"
```

Add the mount to host `config/routes.rb`:

```ruby
mount LunaStyle::Engine => "/luna-style"
```

Keep theme routes inside the engine, not in the host route file. Resolve the
local bundle changes, then inspect the routes:

```sh
bundle install
bin/rails routes
```

Confirm the engine is mounted and its application classes are namespaced under
`LunaStyle`. The engine name, directory, namespace, and asset prefix
agree by convention; no extra namespace configuration is needed.

## 5. Persist the Active Theme

**Goal:** Represent the one active storefront theme with a small, validated
record.

Generate the model from the engine directory so Rails writes files into the
engine rather than the host app:

```sh
cd app/engines/luna_style
bin/rails generate model ThemeSetting key:string theme:string
cd ../../..
```

The generated model belongs at
`app/engines/luna_style/app/models/luna_style/theme_setting.rb`.
Update it to define the allowed choices and the single current setting:

```ruby
module LunaStyle
  class ThemeSetting < ApplicationRecord
    THEMES = %w[classic forest sunrise].freeze

    validates :key, presence: true
    validates :theme, inclusion: { in: THEMES }

    def self.current
      create_or_find_by!(key: "storefront")
    end
  end
end
```

In the generated engine migration, keep the generated migration class name
and timestamp, and make the table match the isolated engine's conventional
name:

```ruby
class CreateLunaStyleThemeSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :luna_style_theme_settings do |t|
      t.string :key, null: false
      t.string :theme, null: false, default: "classic"

      t.timestamps
      t.index :key, unique: true
    end
  end
end
```

The key identifies this one setting as `"storefront"`. The database default
provides `classic` when `current` creates the row. The inclusion validation
rejects unsupported values. The unique index is the authority for key
uniqueness: a model-level uniqueness validator would reject a pre-existing
row before `create_or_find_by!` could handle the database constraint.

Install the engine migration in the host application and migrate:

```sh
bin/rails luna_style:install:migrations
bin/rails db:migrate
```

Inspect the copied migration before running it. Rails places it in the host
`db/migrate` directory with an engine suffix. Let the migration update
`db/schema.rb`; never edit the schema dump directly.

Verify the model behavior in the Rails console:

```sh
bin/rails console
```

```ruby
setting = LunaStyle::ThemeSetting.current
setting.theme
# => "classic"

setting.update!(theme: "forest")
LunaStyle::ThemeSetting.current.theme
# => "forest"

setting.update(theme: "ultraviolet")
# => false
```

The setting is available through a namespaced model and a conventional
`current` method; no theme registry or extra lookup configuration is required.

## 6. Build the Protected Theme Setting

**Goal:** Provide a RESTful, protected interface to the one theme setting.

Declare a singular resource in
`app/engines/luna_style/config/routes.rb`:

```ruby
LunaStyle::Engine.routes.draw do
  resource :theme, only: %i[show update], controller: :themes
end
```

The singular resource represents one application-wide setting and creates only
the show and update routes. The host route listing should include paths under
`/luna-style/theme` for `GET` and `PATCH`.

```sh
bin/rails routes -g luna_style
```

The engine controller should include the existing authentication concern. In
`app/engines/luna_style/app/controllers/luna_style/application_controller.rb`:

```ruby
module LunaStyle
  class ApplicationController < ActionController::Base
    include Authenticate::Authentication
  end
end
```

In
`app/engines/luna_style/app/controllers/luna_style/themes_controller.rb`,
keep the admin policy aligned with Store:

```ruby
module LunaStyle
  class ThemesController < ApplicationController
    before_action :require_admin

    def show
      @theme_setting = ThemeSetting.current
    end

    def update
      @theme_setting = ThemeSetting.current

      if @theme_setting.update(theme_setting_params)
        redirect_to theme_path, notice: "Storefront theme updated."
      else
        render :show, status: :unprocessable_entity
      end
    end

    private
      def require_admin
        return if Current.user&.admin?

        redirect_to "/store", alert: "Administrator access is required."
      end

      def theme_setting_params
        params.expect(theme_setting: [:theme])
      end
  end
end
```

`Authenticate::Authentication` requires a signed-in user by default. The
controller's `before_action` then limits both actions to administrators. The
strong-parameters method accepts only `theme`.

Create `app/engines/luna_style/app/views/luna_style/themes/show.html.erb`:

```erb
<h1>Storefront theme</h1>

<p>Choose the theme used by the product storefront.</p>

<% if @theme_setting.errors.any? %>
  <div class="alert" role="alert">
    <ul>
      <% @theme_setting.errors.full_messages.each do |message| %>
        <li><%= message %></li>
      <% end %>
    </ul>
  </div>
<% end %>

<%= form_with model: @theme_setting,
              scope: :theme_setting,
              url: theme_path,
              method: :patch do |form| %>
  <div>
    <%= form.label :theme, "Active theme" %>
    <%= form.select :theme,
                    LunaStyle::ThemeSetting::THEMES.map { |theme| [theme.titleize, theme] } %>
  </div>

  <%= form.submit "Save theme" %>
<% end %>
```

The explicit `theme_setting` scope matches the parameter read by
`params.expect`. The select options come from the same allowlist as model
validation; validation remains necessary because request parameters can be
crafted outside this form.

Use the application integration helper `sign_in_as` in tests. To create an
administrator from an existing test fixture, call `user.update!(admin: true)`
before signing in. Test both unauthenticated requests and signed-in non-admin
requests; neither may update the setting.

Do not provide public preview or arbitrary CSS input in this mini-project.

## 7. Apply the Theme Across the Application

**Goal:** Make the selected theme and shared design system available to the
host application and every mounted engine.

Expose `luna_style_theme` in the engine's `ThemeHelper`, then register it with
all Rails controller views from the LunaStyle engine initializer:

```ruby
initializer "luna_style.action_controller_helpers" do
  ActiveSupport.on_load(:action_controller_base) do
    helper LunaStyle::ThemeHelper
  end
end
```

Keep `storefront_theme` as a compatibility wrapper if existing Store views use
it. Define semantic CSS custom properties in the engine stylesheet and scope
palette overrides to the shared body attribute:

```css
:root {
  --luna-color-background: #f8fafc;
  --luna-color-surface: #ffffff;
  --luna-color-text: #0f172a;
  --luna-color-border: #cbd5e1;
  --luna-color-accent: #1d4ed8;
  --luna-color-on-accent: #ffffff;
}

body[data-luna-style-theme="forest"] {
  --luna-color-background: #f0fdf4;
  --luna-color-accent: #14532d;
}

body[data-luna-style-theme="sunrise"] {
  --luna-color-background: #fff7ed;
  --luna-color-accent: #9a3412;
}
```

`classic` is the root palette, so it remains the fallback if the theme is
missing. Check text/background contrast when changing palette values, and do
not rely on color alone to communicate state.

Load `luna_style/application` in the host layout and each standalone engine
layout: Authenticate, Portal, Store, Commerce, and LunaStyle. Keep it as a
separate `stylesheet_link_tag` when the layout already loads `:app`; Rails
expands that source and does not treat later strings as additional assets.
Internationalization has no standalone layout, so set its controller to use
the host `application` layout. Set `data-luna-style-theme` on each layout body.
Store should also keep `data-storefront-theme` until callers no longer depend
on it.

Use the shared `--luna-color-*` tokens in component styles. Existing Store CSS
can keep its `--store-color-*` aliases while other engines adopt the global
tokens. Do not add a separate asset manifest or custom asset-path
configuration; verify Propshaft serves the engine-owned stylesheet.

Request the host root and pages in each mounted engine and confirm:

1. Every response includes the shared stylesheet and the active theme body
   attribute.
2. The Store response also retains its compatibility body attribute.
3. Propshaft serves the stylesheet with all three palette definitions.
4. Changing the setting as an administrator updates the theme across
   subsequent requests to every engine.

## 8. Test the Complete Feature

**Goal:** Verify the new engine, the Store experience, and every shared layout.

Add `test/models/luna_style/theme_setting_test.rb`:

```ruby
require "test_helper"

class LunaStyle::ThemeSettingTest < ActiveSupport::TestCase
  test "current creates one classic setting and reuses it" do
    setting = LunaStyle::ThemeSetting.current

    assert_equal "classic", setting.theme
    assert_equal setting, LunaStyle::ThemeSetting.current
  end

  test "only supported themes are valid" do
    setting = LunaStyle::ThemeSetting.current

    LunaStyle::ThemeSetting::THEMES.each do |theme|
      setting.theme = theme
      assert_predicate setting, :valid?
    end

    setting.theme = "ultraviolet"
    assert_not_predicate setting, :valid?
  end

  test "the storefront key has a unique database index" do
    assert LunaStyle::ThemeSetting.connection.index_exists?(
      LunaStyle::ThemeSetting.table_name,
      :key,
      unique: true
    )

    LunaStyle::ThemeSetting.current
    assert_raises(ActiveRecord::RecordNotUnique) do
      LunaStyle::ThemeSetting.insert!({ key: "storefront", theme: "classic" })
    end
  end
end
```

Add `test/integration/luna_style_test.rb`:

```ruby
require "test_helper"

class LunaStyleTest < ActionDispatch::IntegrationTest
  test "theme settings require authentication" do
    get "/luna-style/theme"
    assert_redirected_to "/authenticate/session/new"

    patch "/luna-style/theme",
          params: { theme_setting: { theme: "forest" } }
    assert_redirected_to "/authenticate/session/new"
  end

  test "customers cannot view or update the theme" do
    sign_in_as users(:one)

    get "/luna-style/theme"
    assert_redirected_to "/store"

    patch "/luna-style/theme",
          params: { theme_setting: { theme: "forest" } }
    assert_redirected_to "/store"
    assert_equal "classic", LunaStyle::ThemeSetting.current.reload.theme
  end

  test "administrators can update the theme" do
    administrator = users(:one)
    administrator.update!(admin: true)
    sign_in_as administrator

    get "/luna-style/theme"
    assert_response :success
    assert_select "label[for='theme_setting_theme']", "Active theme"
    assert_select "select[name='theme_setting[theme]'] option", count: 3

    patch "/luna-style/theme",
          params: { theme_setting: { theme: "forest", key: "changed-by-request" } }

    assert_redirected_to "/luna-style/theme"
    setting = LunaStyle::ThemeSetting.current.reload
    assert_equal "forest", setting.theme
    assert_equal "storefront", setting.key
  end

  test "unsupported theme values are rejected" do
    administrator = users(:one)
    administrator.update!(admin: true)
    sign_in_as administrator

    patch "/luna-style/theme",
          params: { theme_setting: { theme: "ultraviolet" } }

    assert_response :unprocessable_entity
    assert_equal "classic", LunaStyle::ThemeSetting.current.reload.theme
  end

  test "storefront renders the active theme and engine stylesheet" do
    LunaStyle::ThemeSetting.current.update!(theme: "sunrise")

    get "/store"

    assert_response :success
    assert_select 'body[data-storefront-theme="sunrise"]'
    assert_select 'link[rel="stylesheet"][href*="luna_style/application"]'

    stylesheet = css_select(
      'link[rel="stylesheet"][href*="luna_style/application"]'
    ).first
    get stylesheet["href"]

    assert_response :success
    assert_includes response.body, "--store-color-accent"
  end

  test "host and mounted engine layouts share LunaStyle" do
    administrator = users(:one)
    administrator.update!(admin: true)
    sign_in_as administrator
    LunaStyle::ThemeSetting.current.update!(theme: "forest")

    [
      "/",
      "/authenticate/session/new",
      "/portal/settings",
      "/store",
      "/commerce/cart",
      "/internationalization/settings",
      "/luna-style/theme"
    ].each do |path|
      get path

      assert_response :success, path
      assert_select 'body[data-luna-style-theme="forest"]', 1, path
      assert_select 'link[rel="stylesheet"][href*="luna_style/application"]', 1, path
    end
  end
end
```

The integration tests use the host's `users(:one)` fixture and `sign_in_as`
helper. If a local change to those helpers is required, inspect the existing
test setup first and keep the new test support narrowly scoped.

Run the focused tests and then the full host suite:

```sh
bin/rails test test/models/luna_style/theme_setting_test.rb
bin/rails test test/integration/luna_style_test.rb
bin/rails test test/integration/store_mount_test.rb
bin/rails test
```

If a targeted test path does not match the repository runner's conventions,
inspect `bin/rails test --help` and use the smallest supported selector; do not
silently omit the test. Run `bin/rails test:system` if a system test is added or
if the implementation changes browser interactions beyond a simple form.

When the server is available, also check the browser flow:

1. Start the app using the repository's documented command.
2. Visit `/store` and confirm the default theme.
3. Sign in as an administrator, visit `/luna-style/theme`, choose another
   theme, and submit.
4. Visit the host root and pages in the mounted engines and confirm the chosen
   theme remains active on each response.
5. Sign in as a non-admin and confirm the settings endpoint cannot change the
   setting.

Tests must cover both the new engine and the host integration boundary; a
passing model test alone does not establish that the engine is mounted,
authorized, or applied across the host and mounted-engine layouts.

## 9. What You Learned

- Rails engine naming and conventional directories connect engine components
  without hand-written autoloading rules.
- A local path gem makes the dependency between Store and the style engine
  explicit.
- A singular resource matches the single application-wide theme setting.
- The engine owns its persistence, route, helper, and CSS, while the host
  application continues to own authentication and users.
- Model validation protects supported values at the application boundary; a
  database index protects uniqueness at the persistence boundary.
- Integration tests verify the feature where the engine meets the host app.

## 10. Acceptance Criteria

- [ ] A `LunaStyle` mountable, isolated engine exists under
      `app/engines/luna_style`.
- [ ] The host app includes the engine as a local path dependency and mounts it
      at `/luna-style`.
- [ ] Store declares its dependency on `luna_style` because it consumes
      the engine helper and model.
- [ ] The engine migration is installed into the host app and creates the
      settings table with a unique key and a database default of `classic`.
- [ ] The current setting is created on demand using the `"storefront"` key.
- [ ] Only `classic`, `forest`, and `sunrise` can be persisted through model
      validation.
- [ ] The singular `/luna-style/theme` resource requires authentication
      and administrator access for both show and update.
- [ ] Strong parameters permit only the theme field; invalid submissions do not
      persist.
- [ ] Every host and mounted-engine body reflects the active theme using
      `data-luna-style-theme`; Store retains `data-storefront-theme`.
- [ ] Propshaft serves the engine-owned stylesheet and every standalone HTML
      layout loads it.
- [ ] The stylesheet defines shared semantic tokens for all three palettes,
      with usable text/background contrast.
- [ ] Focused model and integration tests plus the full host test suite pass.
- [ ] Existing catalog behavior and route tests continue to pass.

## 11. Stretch Challenges

These are not required for acceptance:

- Add a safe, temporary theme preview for administrators without persisting the
  preview choice.
- Add automated color-contrast checks for every token palette.
- Add a browser system test that changes the active theme and verifies the
  storefront after navigation.
- Explore how the convention changes if the application later supports
  per-tenant themes; do not add tenant configuration before that requirement
  exists.

## 12. Official Rails References

The following links and section anchors were checked against the official Rails
Guides while preparing this tutorial:

- [Getting Started with Engines](https://guides.rubyonrails.org/engines.html):
  [Generating an Engine](https://guides.rubyonrails.org/engines.html#generating-an-engine),
  [Mounting the Engine](https://guides.rubyonrails.org/engines.html#mounting-the-engine),
  [Testing an Engine](https://guides.rubyonrails.org/engines.html#testing-an-engine),
  [Assets](https://guides.rubyonrails.org/engines.html#assets), and
  [Other Gem Dependencies](https://guides.rubyonrails.org/engines.html#other-gem-dependencies).
- [Active Record Migrations](https://guides.rubyonrails.org/active_record_migrations.html):
  [Migrations from Engines](https://guides.rubyonrails.org/active_record_migrations.html#migrations-from-engines)
  and [Running Migrations](https://guides.rubyonrails.org/active_record_migrations.html#running-migrations).
- [Active Record Validations](https://guides.rubyonrails.org/active_record_validations.html#validations-overview).
- [Action Controller Overview](https://guides.rubyonrails.org/action_controller_overview.html):
  [Strong Parameters](https://guides.rubyonrails.org/action_controller_overview.html#strong-parameters)
  and [before_action](https://guides.rubyonrails.org/action_controller_overview.html#before-action).
- [Rails Routing from the Outside In](https://guides.rubyonrails.org/routing.html):
  [Resource Routing](https://guides.rubyonrails.org/routing.html#resource-routing-the-rails-default)
  and [Singular Resources](https://guides.rubyonrails.org/routing.html#singular-resources).
- [Testing Rails Applications](https://guides.rubyonrails.org/testing.html):
  [Testing Models](https://guides.rubyonrails.org/testing.html#testing-models),
  [Integration Testing](https://guides.rubyonrails.org/testing.html#integration-testing),
  and [Testing Views](https://guides.rubyonrails.org/testing.html#testing-views).
- [The Asset Pipeline](https://guides.rubyonrails.org/asset_pipeline.html):
  [Propshaft Features](https://guides.rubyonrails.org/asset_pipeline.html#propshaft-features)
  and [Working with Propshaft](https://guides.rubyonrails.org/asset_pipeline.html#working-with-propshaft).
