module BankScrapers
  class Ofx
    include Loggable

    def initialize(opts)
      @options = opts
    end

    def download_data
      ofx_data
    rescue Net::HTTPError => e
      # Discover card gives us forbidden results sometimes
      if e.response.is_a?(Net::HTTPForbidden)
        logger.error("OFX download fail from #{@options['url']}")
      else
        raise "#{e.response.class} from #{@options['url']}"
      end
    end

    def ofx_data
      days_ago = @options['days_ago'] || 80
      ofx_client.account_numbers.collect do |num|
        ofx_client.transaction_data(num, Date.today - days_ago)
      end
    end

    def ofx_client
      @client ||= OfxClient.new(
        :username => @options['username'],
        :password => @options['password'],

        :fi_type => @options['fi_type'].intern,
        :fid => @options['fid'],
        :fiorg => @options['fiorg'],
        :url => @options['url'])
    end
  end
end
