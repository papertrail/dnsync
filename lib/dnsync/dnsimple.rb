require 'faraday'
require 'faraday_middleware'
require 'active_support/core_ext/object/blank'

require 'dnsync/zone'

module Dnsync
  class Dnsimple
    attr_reader :domain

    def initialize(email, token, domain)
      unless email.present?
        raise ArgumentError, "email must be specified"
      end

      unless token.present?
        raise ArgumentError, "token must be specified"
      end

      unless domain.present?
        raise ArgumentError, "domain must be specified"
      end

      @email  = email
      @token  = token
      @domain = domain
    end

    def connection
      @connection ||= Faraday.new('https://api.dnsimple.com/v1/') do |conn|
        conn.request :url_encoded # form-encode POST params

        # conn.response :logger
        conn.response :raise_error
        conn.response :json, :content_type => /\bjson$/

        conn.adapter Faraday.default_adapter

        conn.headers['X-DNSimple-Token'] = "#{@email}:#{@token}"

        conn.options.timeout      = 5
        conn.options.open_timeout = 5
      end
    end

    def zone
      records_by_record = connection.get("domains/#{@domain}/records").body.group_by do |dnsimple_record|
        [ dnsimple_record['record']['name'], dnsimple_record['record']['record_type'] ]
      end

      records = records_by_record.map do |(name, record_type), records|
        fqdn = name.present? ? "#{name}.#{@domain}" : @domain
        ttl = records.first['record']['ttl']

        answers = records.map do |record|
          Answer.new(record['record']['content'], record['record']['prio'])
        end

        Record.new(fqdn, record_type, ttl, answers)
      end

      Zone.new(@domain, records)
    end
  end
end