require "test_helper"
require_relative "../../db/migrate/20261125181000_migrate_legacy_store_users_to_host_users"

class LegacyStoreUserMigrationTest < ActiveSupport::TestCase
  test "copies legacy accounts with their password digest and is idempotent" do
    email = "legacy-migration-#{SecureRandom.hex(8)}@example.com"
    password_digest = BCrypt::Password.create("legacy account test password").to_s
    timestamp = ActiveRecord::Base.connection.quote(Time.current)
    connection = ActiveRecord::Base.connection

    connection.execute <<~SQL
      INSERT INTO store_users (email_address, password_digest, created_at, updated_at)
      VALUES (
        #{connection.quote(email)},
        #{connection.quote(password_digest)},
        #{timestamp},
        #{timestamp}
      )
    SQL

    migration = MigrateLegacyStoreUsersToHostUsers.new
    migration.up
    migration.up

    migrated_user = User.find_by!(email_address: email)
    assert_equal password_digest, migrated_user.password_digest
    assert_equal 1, User.where(email_address: email).count
    assert_equal 1, connection.select_value(
      "SELECT COUNT(*) FROM store_users WHERE email_address = #{connection.quote(email)}"
    )
  end
end
