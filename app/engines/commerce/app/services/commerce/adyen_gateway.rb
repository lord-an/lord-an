require "adyen-ruby-api-library"
require "json"
require "uri"

module Commerce
  class AdyenGateway
    class Error < StandardError; end

    SESSION_LIFETIME = 1.hour

    def initialize(client: nil)
      @client = client
    end

    def create_session(order:, return_url:)
      response = adyen_client.checkout.payments_api.sessions(
        session_payload(order, return_url),
        headers: { "Idempotency-Key" => order.merchant_reference }
      )
      body = response.response
      url = URI.parse(body.fetch("url"))
      unless url.scheme == "https" && url.port == 443 && url.userinfo.nil? &&
        url.host&.match?(/\A[a-z0-9.-]+\.(?:adyen\.com|adyenpayments\.com)\z/i)
        raise Error, "Adyen returned an invalid checkout URL"
      end

      {
        id: body.fetch("id"),
        url: url.to_s,
        expires_at: Time.zone.parse(body.fetch("expiresAt", SESSION_LIFETIME.from_now.iso8601))
      }
    rescue Error
      raise
    rescue Adyen::AdyenError, Faraday::Error, JSON::ParserError, KeyError, URI::InvalidURIError, ArgumentError => error
      raise Error, "Adyen returned an invalid session response: #{error.class}"
    end

    private
      def adyen_client
        return @client if @client

        environment = ENV.fetch("ADYEN_ENVIRONMENT")
        options = {
          api_key: ENV.fetch("ADYEN_API_KEY"),
          env: environment.to_sym,
          application_name: "LordAn/1.0"
        }
        options[:live_url_prefix] = ENV.fetch("ADYEN_LIVE_PREFIX") if environment == "live"
        Adyen::Client.new(**options)
      end

      def session_payload(order, return_url)
        {
          amount: { currency: order.currency_code, value: order.total_cents },
          countryCode: order.shipping_country_code,
          channel: "Web",
          merchantAccount: ENV.fetch("ADYEN_MERCHANT_ACCOUNT"),
          reference: order.merchant_reference,
          returnUrl: return_url,
          shopperEmail: order.user.email_address
        }
      end
  end
end
