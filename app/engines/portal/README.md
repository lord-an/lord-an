# Portal engine

Mountable account-management engine for signed-in users. It uses the
`Authenticate` engine's shared session handling and the host application's
`User` model. Account details are edited from the unified settings experience;
language preferences are managed there separately.

Mount it at `/portal`:

```ruby
mount Portal::Engine => "/portal"
```

The unified settings page is available at `/settings`. The legacy
`/portal/settings` destination redirects to its account section. The Portal
engine owns account detail editing at `/portal/settings/edit`.

## Usage
How to use my plugin.

## Installation
Add this line to your application's Gemfile:

```ruby
gem "portal"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install portal
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
