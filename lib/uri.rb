require 'imw/dataset/uri/file_store'
require 'imw/dataset/uuid'
module Addressable
  #
  # Add the #scrubbed and #revhost calls
  #
  class URI
    SAFE_CHARS      = %r{a-zA-Z0-9\-\._!\(\)\*\'}
    PATH_CHARS      = %r{#{SAFE_CHARS}\$&\+,:=@\/;}
    RESERVED_CHARS  = %r{\$&\+,:=@\/;\?\%}
    UNSAFE_CHARS    = %r{\\ \"\#<>\[\]\^\`\|\~\{\}}
    HOST_HEAD     = '(?:[A-Z0-9\-]+\.)+'
    HOST_TLD      = '(?:[A-Z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|jobs|museum)'

    def path_with_strip
      path_str = path_without_strip
      return '/' if path_str.blank?
      path_str.gsub!(%r{([^/])/+$},'\1')
      @path = path_str
    end
    alias_method_chain :path, :strip unless defined?(path_without_strip)

    def host_valid?
      !!(host =~ %r{\A#{HOST_HEAD}#{HOST_TLD}\z}i)
    end

    def path_valid?
      !!(path =~ %r{\A[#{PATH_CHARS}%]*\z})
    end

    #
    # can the uri be reproduced from its scrubbed representation?
    #
    def simple?
      host_valid? &&
        path_valid? &&
        (scheme == 'http' && port == 80)  &&
        self.to_hash.values_at(:password, :user).join.blank?
    end

    #
    # +revhost+
    # the dot-reversed host:
    #   foo.company.com => com.company.foo
    #
    def revhost
      return host unless host =~ /\./
      host.split('.').reverse.join('.')
    end
    #
    # +uuid+  -- RFC-4122 ver.5 uuid; guaranteed to be universally unique
    #
    # See
    #   http://www.faqs.org/rfcs/rfc4122.html
    #
    def url_uuid
      UUID.sha1_create(UUID_URL_NAMESPACE, self.normalize.to_s)
    end
  end
end

