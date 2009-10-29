class Account
  class << self
    def all
      @accounts ||= BankAgent.config['accounts'].map do |a|
        handler(a['type']).new(a)
      end
    end

    def handler(name)
      BankAgent.const_get(name)
    end
  end

  def initialize(opts)
    @options = opts
  end

  def name
    @options['name']
  end

  def update
    import_transactions(scraper_results)
  end

  def import_transactions(data)
    puts data.inspect
  end

  def scraper_results
    klass = BankScrapers.const_get(@options['source'] || @options['type'])
    data = klass.new(@options).download
    data.is_a?(Array) ? data.first : data
  end
end
