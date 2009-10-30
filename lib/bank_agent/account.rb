module BankAgent
  class Account
    include Loggable

    def self.import(path, opts)
      new(opts).import_results(File.read(path))
    end

    def self.update(*opts)
      [ *opts ].flatten.each do |options|
        new(options).update
      end
    end

    def initialize(opts)
      @options = opts
    end

    def update
      if (data = fetch_results)
        backup_results(data)
        import_results(data)
      else
        puts "Failed to download #{@options['name']}"
      end
    end

    def import_results(data)
      parser = adapter(data)
      client.import parser.bank_data
    end

    def fetch_results
      klass = Scrapers.const_get(@options['source'] || @options['type'])
      data = klass.new(@options).download_data
      data.is_a?(Array) ? data.first : data
    end

    def adapter(data)
      Adapters.const_get(@options['type']).new(data)
    end

    def client
      Clients.const_get(BankAgent.config['client']['type']).new(BankAgent.config['client'], @options)
    end

    def backup_results(data)
      # TODO save data to s3
      # put enc data in meta keys
      File.open(@options['name'] + '_data', 'w') do |file|
        file.write(data)
      end
    end
  end
end
