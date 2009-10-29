class Account
  include Loggable

  def initialize(opts)
    @options = opts
  end

  def update
    if (data = fetch_results)
      backup_results(data)
      agent(data).import_transactions
    else
      puts "Failed to download #{@options['name']}"
    end
  end

  def fetch_results
    klass = BankScrapers.const_get(@options['source'] || @options['type'])
    data = klass.new(@options).download_data
    data.is_a?(Array) ? data.first : data
  end

  def agent(data)
    BankAgent.const_get(@options['type']).new(data, @options)
  end

  def backup_results(data)
    # TODO save data to s3
    # put enc data in meta keys
    File.open(@options['name'] + '_data', 'w') do |file|
      file.write(data)
    end
  end
end
