require 'dragonfly'
require 'dragonfly/s3_data_store'
require 'uri'

# Configure
Dragonfly.app.configure do
  plugin :imagemagick

  secret "5fc2f8d11fb3d4ad28a4c4e3e353d2ca9e041e14930d48a5c1242613f9cdd2cc"

  url_format "/media/:job/:name"
    
  if ENV["DATASTORE_S3"].present?
    
    fog_storage_options = Hash.new

    if ENV["DATASTORE_S3_PATH_STYLE"].present?
      fog_storage_options["path_style"] = true
    end

    url_host = nil
    url_scheme = nil

    if ENV["DATASTORE_S3_ENDPOINT"].present?

      # monkey patch the Dragonfly::S3DataStore to remove the call to storage.sync_clock which unfortunately uses a hard coded "s3.amazonaws.com" hostname
      Dragonfly::S3DataStore.class_eval do
        def storage
          @storage ||= begin
            storage = Fog::Storage.new(fog_storage_options.merge({
              :provider => 'AWS',
              :aws_access_key_id => access_key_id,
              :aws_secret_access_key => secret_access_key,
              :region => region,
              :use_iam_profile => use_iam_profile
            }).reject {|name, option| option.nil?})
            # storage.sync_clock
            storage
          end
        end
      end

      endpoint = URI.parse(ENV["DATASTORE_S3_ENDPOINT"])
      url_host = endpoint.host
      url_scheme = endpoint.scheme
      if !((endpoint.port == 80 && endpoint.scheme == "http") || (endpoint.port == 443 && endpoint.scheme == "https"))
        url_host = "#{endpoint.host}:#{endpoint.port}"
      end
      fog_storage_options["endpoint"] = ENV["DATASTORE_S3_ENDPOINT"]
    end

    datastore :s3,
      use_iam_profile: false,
      bucket_name: ENV["DATASTORE_S3_BUCKET_NAME"],
      region: ENV["DATASTORE_S3_REGION"],
      access_key_id: ENV["DATASTORE_S3_ACCESS_KEY_ID"],
      secret_access_key: ENV["DATASTORE_S3_SECRET_ACCESS_KEY"],
      root_path: ENV["DATASTORE_S3_ROOT_PATH"],
      url_host: url_host,
      url_scheme: url_scheme,
      fog_storage_options: fog_storage_options
  else
    datastore :file,
      root_path: Rails.root.join('public/system/dragonfly', Rails.env),
      server_root: Rails.root.join('public')
  end
end

# Logger
Dragonfly.logger = Rails.logger

# Mount as middleware
Rails.application.middleware.use Dragonfly::Middleware

# Add model functionality
if defined?(ActiveRecord::Base)
  ActiveRecord::Base.extend Dragonfly::Model
  ActiveRecord::Base.extend Dragonfly::Model::Validations
end
