# Authenticate engine

Mountable authentication engine providing signup, login, logout, and password
reset using the host application's `User` and `Session` models.

Mount it at `/authenticate`:

```ruby
mount Authenticate::Engine => "/authenticate"
```

Available flows:

- `/authenticate/registrations/new` — sign up
- `/authenticate/session/new` — log in
- `/authenticate/passwords/new` — request a password reset

## Usage
How to use my plugin.

## Installation
Add this line to your application's Gemfile:

```ruby
gem "authenticate"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install authenticate
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
