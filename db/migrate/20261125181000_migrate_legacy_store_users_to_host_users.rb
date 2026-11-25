class MigrateLegacyStoreUsersToHostUsers < ActiveRecord::Migration[8.1]
  def up
    suppress_messages do
      migrate_legacy_users
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private
    def migrate_legacy_users
      legacy_users = select_all(<<~SQL)
        SELECT email_address, password_digest, created_at, updated_at
        FROM store_users
        ORDER BY id
      SQL
      legacy_users_with_emails = legacy_users.map do |user|
        email = normalized_email(user["email_address"])
        raise "A legacy Store account has a blank email address; resolve it before migrating." unless email

        [ user, email ]
      end

      normalized_emails = legacy_users_with_emails.map(&:last)
      if normalized_emails.uniq.length != normalized_emails.length
        raise "Legacy Store accounts contain duplicate normalized email addresses; resolve them before migrating."
      end

      legacy_users_with_emails.each do |user, email|
        next if select_value(<<~SQL)
          SELECT 1
          FROM users
          WHERE LOWER(TRIM(email_address)) = #{quote(email)}
          LIMIT 1
        SQL

        execute <<~SQL
          INSERT INTO users (email_address, password_digest, created_at, updated_at)
          VALUES (
            #{quote(email)},
            #{quote(user["password_digest"])},
            #{quote(user["created_at"])},
            #{quote(user["updated_at"])}
          )
        SQL
      end
    end

    def normalized_email(email)
      email.to_s.strip.downcase.presence
    end
end
