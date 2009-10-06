require 'rexml/document'
require 'uri'
require 'cgi'

class Hash #:nodoc:all
   # Taken from Rails, with appreciation to DHH
   def stringify_keys
     inject({}) do |options, (key, value)|
       options[key.to_s] = value
       options
     end
   end unless method_defined?(:stringify_keys)
end

module Vuzit

  # Class for uploading, loading, and deleting documents using the Vuzit Web
  # Service API: http://vuzit.com/developer/documents_api
  #
  # To use this class you need to {sign up}[http://vuzit.com/signup] for 
  # Vuzit first.
  class Document
    # The document ID
    attr_accessor :id 

    # The document title
    attr_accessor :title 

    # The document subject
    attr_accessor :subject 

    # Number of pages of the document
    attr_accessor :page_count 

    # Page width of the document in pixels
    attr_accessor :page_width 

    # Page height of the document in pixels
    attr_accessor :page_height 

    # File size of the original document bytes
    attr_accessor :file_size 

    TRIES = 3 #:nodoc:

    # Constructor.  
    def initialize #:nodoc:
      # Set the defaults
      @id = @title = @subject = nil
      @page_count = @page_width = @page_height = @file_size = -1
    end

    # Deletes a document by the ID.  Returns true if it succeeded.  It throws
    # a Vuzit::ClientException on failure.  It returns _true_ on success.  
    #
    # Example:
    #
    #  Vuzit::Service.public_key = 'YOUR_PUBLIC_API_KEY'
    #  Vuzit::Service.private_key = 'YOUR_PRIVATE_API_KEY'
    # 
    #  result = Vuzit::Document.destroy("DOCUMENT_ID")
    def self.destroy(id)
      timestamp = Time.now
      sig = CGI.escape(Vuzit::Service::get_signature('destroy', id, timestamp))

      # Create the connection
      uri = URI.parse(Vuzit::Service.service_url)
      http = Net::HTTP.new(uri.host, uri.port)

      query = "/documents/#{id}.xml?key=#{Vuzit::Service.public_key}" +
              "&signature=#{sig}&timestamp=#{timestamp.to_i}"
      request = Net::HTTP::Delete.new(query, {'User-Agent' => Vuzit::Service.user_agent})
      response = http.start { http.request(request) }

      if response.code.to_i != 200
        # Some type of error ocurred
        begin
          doc = REXML::Document.new(response.body)
        rescue Exception => ex
          raise Vuzit::ClientException.new("XML error: #{ex.message}")
        end

        if doc.root != nil
          code = doc.root.elements['code']
          if code != nil
            raise Vuzit::ClientException.new(doc.root.elements['msg'].text, code.text.to_i);
          end
        end

        # At this point we don't know what the error is 
        raise Vuzit::ClientException.new("Unknown error occurred #{response.message}", response.code)
      end

      debug(response.code + " " + response.message + "\n")

      return true
    end

    # Finds a document by the ID.  It throws a Vuzit::ClientException on failure. 
    # 
    # Example:
    #
    #  Vuzit::Service.public_key = 'YOUR_PUBLIC_API_KEY'
    #  Vuzit::Service.private_key = 'YOUR_PRIVATE_API_KEY'
    # 
    #  doc = Vuzit::Document.find("DOCUMENT_ID")
    #  puts doc.id
    #  puts doc.title
    def self.find(id)
      timestamp = Time.now
      sig = CGI.escape(Vuzit::Service::get_signature('show', id, timestamp))

      # Create the connection
      uri = URI.parse(Vuzit::Service.service_url)
      http = Net::HTTP.new(uri.host, uri.port)

      query = "/documents/#{id}.xml?key=#{Vuzit::Service.public_key}" +
              "&signature=#{sig}&timestamp=#{timestamp.to_i}"
      request = Net::HTTP::Get.new(query, {'User-Agent' => Vuzit::Service.user_agent})
      response = http.start { http.request(request) }

      # TODO: Check if response.code.to_i != 200

      begin
        doc = REXML::Document.new(response.body)
      rescue Exception => ex
        raise Vuzit::ClientException.new("XML error: #{ex.message}")
      end

      if doc.root == nil
        raise Vuzit::ClientException.new("No response from server");
      end

      debug(response.code + " " + response.message + "\n" + response.body)

      code = doc.root.elements['code']
      if code != nil
        raise Vuzit::ClientException.new(doc.root.elements['msg'].text, code.text.to_i);
      end

      id = doc.root.elements['web_id']
      if id == nil
        raise Vuzit::ClientException.new("Unknown error occurred");
      end

      result = Vuzit::Document.new
      result.id = id.text
      result.title = doc.root.elements['title'].text
      result.subject = doc.root.elements['subject'].text
      result.page_count = doc.root.elements['page_count'].text.to_i
      result.page_width = doc.root.elements['width'].text.to_i
      result.page_height = doc.root.elements['height'].text.to_i
      result.file_size = doc.root.elements['file_size'].text.to_i

      return result
    end

    # Uploads a file to Vuzit. It throws a Vuzit::ClientException on failure.
    #
    # Example:
    #
    #  Vuzit::Service.public_key = 'YOUR_PUBLIC_API_KEY'
    #  Vuzit::Service.private_key = 'YOUR_PRIVATE_API_KEY'
    # 
    #  doc = Vuzit::Document.upload("c:/path/to/document.pdf", :secure => true)
    #  puts doc.id
    def self.upload(file, options = {})
      raise ArgumentError, "Options must be a hash" unless options.kind_of? Hash

      if !File.exists?(file)
        raise Vuzit::ClientException.new("The file could not be found: #{file}")
      end

      timestamp = Time.now
      sig = Vuzit::Service::get_signature('create', nil, timestamp)
      # Make a request form
      fields = Hash.new
      fields[:format] = 'xml'
      fields[:key] = Vuzit::Service::public_key

      if options[:secure] != nil
        fields[:secure] = options[:secure] == true ? '1' : '0'
      else
        fields[:secure] = '1'
      end

      fields[:signature] = sig
      fields[:timestamp] = timestamp.to_i
      fields[:file_type] = options[:file_type]
      response = nil

      File.open(file, "rb") do |f|
        fields[:upload] = f
        response = send_request 'create', fields
      end

      debug(response.code + " " + response.message + "\n" + response.body)

      # TODO: check the response.code.to_i to make sure it's 201

      begin
        doc = REXML::Document.new(response.body)
      rescue Exception => ex
        raise Vuzit::ClientException.new("XML error: #{ex.message}")
      end

      if doc.root == nil
        raise Vuzit::ClientException.new("No response from server");
      end

      code = doc.root.elements['code']
      if code != nil
        raise Vuzit::ClientException.new(doc.root.elements['msg'].text, code.text.to_i);
      end

      id = doc.root.elements['web_id']
      if id == nil
        raise Vuzit::ClientException.new("Unknown error occurred");
      end

      result = Vuzit::Document.new
      result.id = id.text

      return result
    end

    private

    # Sends debug messages if activated
    def self.debug(text)
      $stderr.puts(text) if Vuzit::Service::debug == true
    end

    # Makes a HTTP POST.  
    def self.send_request(method, fields = {})
      # See if method is given
      raise ArgumentError, "Method should be given" if method.nil? || method.empty?
      
      debug("** Remote method call: #{method}; fields: #{fields.inspect}")
      
      # replace pesky hashes to prevent accidents
      fields = fields.stringify_keys

      # Complete fields with the method name
      fields['method'] = method
      
      fields.reject! { |k, v| v.nil? }

      debug("** POST parameters: #{fields.inspect}")

      # Create the connection
      uri = URI.parse(Vuzit::Service.service_url)
      http = Net::HTTP.new(uri.host, uri.port)

      # API methods can be SLOW.  Make sure this is set to something big to prevent spurious timeouts
      http.read_timeout = 15 * 60

      request = Net::HTTP::Post.new('/documents', {'User-Agent' => Vuzit::Service.user_agent})
      request.multipart_params = fields

      tries = TRIES
      begin
        tries -= 1
        res = http.request(request)
      rescue Exception
        $stderr.puts "Request encountered error, will retry #{tries} more."
        if tries > 0
          # Retrying several times with sleeps is recommended.
          # This will prevent temporary downtimes
          sleep(20)
          retry
        end
        raise $!
      end
      return res
    end

  end

end
