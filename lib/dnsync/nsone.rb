module Dnsync
  class Nsone
    def initialize(api_key, domain)
      unless api_key.present?
        raise ArgumentError, "api_key must be specified"
      end

      unless domain.present?
        raise ArgumentError, "domain must be specified"
      end
      
      @api_key = api_key
      @domain  = domain
    end
    
    def connection
      @connection ||= Faraday.new('https://api.nsone.net/v1/') do |conn|
        conn.request :json

        # conn.response :logger
        conn.response :raise_error
        conn.response :json, :content_type => /\bjson$/

        conn.adapter Faraday.default_adapter

        conn.headers['X-NSONE-Key'] = @api_key

        conn.options.timeout      = 5
        conn.options.open_timeout = 5
      end
    end

    def zone
      zone = connection.get("zones/#{@domain}").body
      
      records = zone['records'].map do |record|
        record_for(record['domain'], record['type'])
      end
      
      Zone.new(@domain, records)
    end
    
    def record_for(fqdn, record_type)
      record = connection.get("zones/#{@domain}/#{fqdn}/#{record_type}").body
      
      answers = record['answers'].map do |answer_record|
        case answer_record['answer'].length
        when 2
          priority, content = *answer_record['answer']
        when 1
          content = answer_record['answer'].first
        else
          raise "Unknown answer format: #{answer_record.inspect}"
        end
        
        Answer.new(content, priority)
      end
      
      Record.new(record['domain'], record['type'], record['ttl'], answers)
    rescue Faraday::ClientError => ex
      if ex.response[:status].to_i == 429
        sleep 0.4 + rand
        retry
      else
        raise
      end
    end

    def create_record(record)
      answers = record.answers.map do |answer|
        if answer.priority
          { :answer => [ answer.priority, answer.content ] }
        else
          { :answer => [ answer.content ] }
        end
      end

      connection.put("zones/#{@domain}/#{record.name}/#{record.type}") do |req|
        req.body = {
          :type    => record.type,
          :zone    => @domain,
          :domain  => record.name,
          :ttl     => record.ttl,
          :answers => answers
        }
      end
    end

    def update_record(record)
      answers = record.answers.map do |answer|
        if answer.priority
          { :answer => [ answer.priority, answer.content ] }
        else
          { :answer => [ answer.content ] }
        end
      end

      connection.post("zones/#{@domain}/#{record.name}/#{record.type}") do |req|
        req.body = {
          :type    => record.type,
          :zone    => @domain,
          :domain  => record.name,
          :ttl     => record.ttl,
          :answers => answers
        }
      end
    end

    def remove_record(record)
      connection.delete("zones/#{@domain}/#{record.name}/#{record.type}")
    end
  end
end