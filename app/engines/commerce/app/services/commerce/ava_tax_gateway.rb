require "net/http"
require "uri"

module Commerce
  class AvaTaxGateway
    class Error < StandardError; end

    def calculate(order:)
      response = request("/api/v2/transactions/createoradjust", transaction_payload(order))
      tax = BigDecimal(JSON.parse(response.body).fetch("totalTax").to_s)
      (tax * 100).round(0, :half_up).to_i
    rescue JSON::ParserError, KeyError, ArgumentError => error
      raise Error, "AvaTax returned an invalid tax response: #{error.class}"
    end

    def commit(order:)
      request(transaction_path(order, "commit"), { commit: true })
    end

    def void(order:)
      return if order.tax_voided_at? || order.tax_committed_at?

      request(transaction_path(order, "void"), { code: "DocVoided" })
      order.update!(tax_voided_at: Time.current)
    end

    private
      def transaction_payload(order)
        {
          type: "SalesOrder",
          code: order.tax_transaction_code,
          companyCode: ENV.fetch("AVATAX_COMPANY_CODE"),
          date: order.created_at.to_date.iso8601,
          customerCode: "customer-#{order.user_id}",
          currencyCode: order.currency_code,
          commit: false,
          addresses: {
            shipFrom: {
              line1: ENV.fetch("MERCHANT_ORIGIN_LINE1"),
              city: ENV.fetch("MERCHANT_ORIGIN_CITY"),
              region: ENV.fetch("MERCHANT_ORIGIN_REGION"),
              country: ENV.fetch("MERCHANT_ORIGIN_COUNTRY_CODE"),
              postalCode: ENV.fetch("MERCHANT_ORIGIN_POSTAL_CODE")
            },
            shipTo: {
              line1: order.shipping_line1,
              line2: order.shipping_line2,
              city: order.shipping_city,
              region: order.shipping_region,
              country: order.shipping_country_code,
              postalCode: order.shipping_postal_code
            }.compact
          },
          lines: order.items.map do |item|
            {
              number: item.id.to_s,
              quantity: item.quantity,
              amount: amount(item.total_cents),
              itemCode: (item.product_id || item.id).to_s,
              taxCode: item.avatax_tax_code,
              description: item.product_name
            }
          end + [ {
            number: "shipping",
            quantity: 1,
            amount: amount(order.shipping_cents),
            itemCode: "shipping",
            taxCode: "FR020100",
            description: "Standard shipping"
          } ]
        }
      end

      def request(path, payload)
        uri = URI.join(api_url, path)
        request = Net::HTTP::Post.new(uri)
        request.basic_auth(ENV.fetch("AVATAX_ACCOUNT_ID"), ENV.fetch("AVATAX_LICENSE_KEY"))
        request["Content-Type"] = "application/json"
        request["X-Avalara-Client"] = "LordAn/1.0 (Ruby; Rails)"
        request.body = JSON.generate(payload)

        response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 15) do |http|
          http.request(request)
        end
        raise Error, "AvaTax request failed with status #{response.code}" unless response.is_a?(Net::HTTPSuccess)

        response
      rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, IOError, SystemCallError => error
        raise Error, "AvaTax request failed: #{error.class}"
      end

      def transaction_path(order, action)
        company = URI.encode_www_form_component(ENV.fetch("AVATAX_COMPANY_CODE"))
        code = URI.encode_www_form_component(order.tax_transaction_code)
        "/api/v2/companies/#{company}/transactions/#{code}/#{action}"
      end

      def api_url
        case ENV.fetch("AVATAX_ENVIRONMENT")
        when "sandbox" then "https://sandbox-rest.avatax.com"
        when "production" then "https://rest.avatax.com"
        else raise Error, "AVATAX_ENVIRONMENT must be sandbox or production"
        end
      end

      def amount(cents)
        BigDecimal(cents.to_s).div(100).to_s("F")
      end
  end
end
