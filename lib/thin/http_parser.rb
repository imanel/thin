require 'http/parser'
require 'uri'

module Thin
  class HttpParser < HTTP::Parser
    
    def initialize(*args)
      super
      
      self.on_headers_complete = proc { |h| build_headers(h) }
      self.on_body             = proc { |b| @headers['rack.input'] << b }
      self.on_message_complete = proc { @finished = true }
    end
    
    def execute(env, data, nparsed)
      self << data[nparsed..-1]
      env.merge! headers
      data.length
    end
    
    def finished?
      !!@finished
    end
    
    private
    
    def headers
      @headers ||= {}
    end
    
    def build_headers(h)
      headers
      h.each do |k, v|
        key = k.gsub('-','_').upcase
        prefix = ['CONTENT_TYPE', 'CONTENT_LENGTH'].include?(key) ? '' : 'HTTP_'
        @headers[prefix + key] = v
      end
      
      host                        = URI.parse @headers['HTTP_HOST'] ? 'http://' + @headers['HTTP_HOST'] : ''
      @headers['SERVER_NAME']     = host.host || 'localhost'
      @headers['SERVER_PORT']     = host.port ? host.port.to_s : '80'
      @headers['REQUEST_METHOD']  = self.http_method
      @headers['REQUEST_URI']     = self.request_url
      @headers['QUERY_STRING']    = self.query_string
      @headers['SERVER_PROTOCOL'] = 'HTTP/' + self.http_version.join('.')
      @headers['HTTP_VERSION']    = 'HTTP/' + self.http_version.join('.')
      @headers['SCRIPT_NAME']     = self.request_path.gsub(/\/\Z/,'')
      @headers['REQUEST_PATH']    = self.request_path
      @headers['PATH_INFO']       = self.request_path
      @headers['FRAGMENT']        = self.fragment
      @headers['rack.input']      = StringIO.new('')
      @headers['rack.url_scheme'] = 'http'
    end
    
  end
end
