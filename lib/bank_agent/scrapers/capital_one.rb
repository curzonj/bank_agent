module BankAgent::Scrapers
  class CapitalOne < Base
    def login
      # cofisso_btn_login.x=25&cofisso_btn_login.y=10
      page = request { agent.post("https://login.capitalone.com/loginweb/login/login.do",
                                    'user' => @options['username'], 'password' => @options['password']) }

      raise InvalidLoginError.new unless page.body.match('redirIfCookiePresent')

      # This is required to complete the login
      request { agent.get "https://servicing.capitalone.com/c1/LoginLanding.aspx?startpg=accsumm&setdefaultpg=n" }
    end

    def download(from=nil, to=Date.today)
      from ||= to - days_ago
      output = request { agent.get "https://servicing.capitalone.com/c1/accounts/download.ashx?index=1&from=#{from.strftime('%Y-%m-%d')}&to=#{to.strftime('%Y-%m-%d')}&type=ofx" }

      return_ofx output
    end

  end
end
