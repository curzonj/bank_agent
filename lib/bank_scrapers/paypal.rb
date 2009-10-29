module BankScrapers
  class Paypal < OnlineAccountRobot

    def login
      page = request { agent.get "https://www.paypal.com/us/cgi-bin/webscr?cmd=_login-run" }
      form = page.form('login_form')

      form['login_email'] = @options['username']
      form['login_password']  = @options['password']

      page = request { form.click_button }
    end

    def download
      page = request { agent.get "https://history.paypal.com/us/cgi-bin/webscr?cmd=_history-download&nav=0.3.1" }
      form = page.form('form1')

      from = Date.today - (days_ago || 80)
      to = Date.today

      form.radiobuttons_with(:name => 'type', :value => 'custom_date_range').first.check
      form['custom_file_type'] = 'comma_balaffecting'
      form['from_a'] = from.month
      form['from_b'] = from.day
      form['from_c'] = from.year
      form['to_a']   = to.month
      form['to_b']   = to.day
      form['to_c']   = to.year

      page = request { form.click_button }

      page.body
    end

  end
end
