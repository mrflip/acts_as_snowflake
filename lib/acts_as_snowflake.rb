# ActsAsSnowflake
require 'rubygems'
require 'imw/dataset/uuid'
require 'imw/dataset/uri'

#
# This module will make your resources take their #id as a UUID
#
#
#
# [UUID_DNS_NAMESPACE]
#
# UUID_DNS_NAMESPACE
# UUID_URL_NAMESPACE
# UUID_OID_NAMESPACE
# UUID_X500_NAMESPACE
#

module ActsAsSnowflake

  # base.send(:before_create, :make_uuid_before_create)
  def self.included(base)
    base.extend(ClassMethods)
  end

  # Create ID from current timestamp
  # this, obviously, can be called exactly and only once in an object's lifetime.
  def new_timestamp_and_uuid()
    u = UUID.timestamp_create()
    [u.hexdigest, u.timestamp]
  end

  # Create namespaced ID from the instance method given to acts_as_snowflake
  # (some method which guaranteed intrinsic uniqueness -- a URL, say, or a
  # permalink)
  def namespaced_uuid()
    UUID.sha1_create(self.class.uuid_namespace, self.send(self.class.uuid_generating_method)).hexdigest
  end

  module ClassMethods
    #
    # Give a UUID generation strategy and (unless :timestamp) a method to
    # generate the UUID from:
    #
    #
    # [+:dns+]  generating_method should return a dns octet string unique to this resource.
    # [+:url+]  generating_method should return a URL string unique to this resource.
    # [+:oid+]  generating_method should return an OID identifier unique to this resource.
    # [+:x500+] generating_method should return an X.500 identifier  unique to this resource.
    #
    # [(Any UUID instance)]
    #    Creates UUIDs in the namespace given by the given UUID
    #    generating_method should return an arbitrary string unique to this resource.
    #
    # [(A url-looking string)]
    #    Creates a UUID from the given string, and makes UUIDs within in tha namespace.
    #    generating_method should return an arbitrary string unique to this resource.
    #
    # [+:timestamp+]
    #   UUID created from the current timestamp, and not on any intrinsic
    #
    # == About Namespaces and UUIDs ==
    #
    # If I create a :url and a month later you do too, we get the same UUID.
    #
    # If I create a UUID in my namespace, I'll get the same one any other time I
    # generate from that string, but am guaranteed not to collide with a UUID
    # generated in your namespace.
    #
    # ---
    #
    # And please: always remember that you are unique, just like everyone else.
    #
    def acts_as_snowflake strategy, generating_method=nil
      # stuff in the class accessors we need
      cattr_accessor :uuid_namespace
      cattr_accessor :uuid_generating_method
      self.uuid_generating_method = generating_method
      self.class_eval do
        #
        # Set before_filter
        #
        case strategy
        when :timestamp
          def before_create_with_uuid() before_create_without_uuid; self.uuid, self.created_at = new_timestamp_and_uuid  end
        when :dns, :uri, :oid, :x500, UUID, String
          def before_create_with_uuid() before_create_without_uuid; self.uuid = namespaced_uuid  end
        else raise BadStrategyError, strategy
        end
        alias_method_chain :before_create, :uuid
      end

      #
      # set generating method
      #
      if (strategy != :timestamp) && !generating_method
        raise MissingGeneratingMethod
      end
      case strategy
      when :timestamp
        # no namespace needed
      when :dns         then self.uuid_namespace = UUID_DNS_NAMESPACE
      when :url         then self.uuid_namespace = UUID_URL_NAMESPACE
      when :oid         then self.uuid_namespace = UUID_OID_NAMESPACE
      when :x500        then self.uuid_namespace = UUID_X500_NAMESPACE
      when UUID         then self.uuid_namespace = UUID.sha1_create(UUID_URL_NAMESPACE, strategy)
      when String
        warn "This is supposed to be a URL namespace" unless (strategy =~ %r{^http://})
        # strategy is taken to be a URL, namespace generated from it.
        #
        # there are, of course, a lot of URLs that don't match the above
        # regexp -- but this is just a convenience method; just pass in
        # UUID.sha1_create(UUID_URL_NAMESPACE, 'scheme:your_url')
        # if http:// doesn't do it for you.
        #
        self.uuid_namespace = UUID.sha1_create(UUID_URL_NAMESPACE, strategy)
      else
        raise BadStrategyError, strategy
      end
    end
  end

  class BadStrategyError < ArgumentError
    def initialize(strategy) @strategy = strategy end
    def to_s
      "Need to specify a strategy, a UUID namespace, or a URL to create a namespace (got strategy '#{@strategy.inspect}')" end
  end
  class MissingGeneratingMethod < ArgumentError
    def to_s
      "Need to specify a method to generate the UUID from (or use :timestamp)"
    end
  end

end


