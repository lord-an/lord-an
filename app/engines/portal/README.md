# Portal engine

Mountable account settings engine for signed-in users. It uses the
`Authenticate` engine's shared session handling and the host application's
`User` model.

Mount it at `/portal`:

```ruby
mount Portal::Engine => "/portal"
```

The account settings page is available at `/portal/settings` and allows users
to change their email address and password.

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
