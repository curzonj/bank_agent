module BankScrapers
  class OnlineAccountRobot
    include Loggable

    def initialize(opts)
      @options = opts
      agent.keep_alive = false
    end

    def download_data
      login
      download
    end

    def days_ago
      @options['days_ago'] || 80  
    end

    def return_ofx(output)
      if output.is_a?(WWW::Mechanize::File) && output.body.match(/DATA:OFXSGML/)
        return output.body
      else
        raise unknown_page(output)
      end
    end

    def request(time=1)
      retryable(:on => StandardError, :times => 2) do
        sleep time
        yield
      end
    end

    def agent
      @agent ||= WWW::Mechanize.new {|a| a.log = logger }
    end

    def unknown_page(page)
      raise "Unknown page error on #{page.uri}\n\n#{page.body}"
    end
  end
end
