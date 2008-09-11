require 'acts_as_snowflake'
ActiveRecord::Base.send(:include, ActsAsSnowflake)
