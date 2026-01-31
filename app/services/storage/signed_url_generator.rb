# frozen_string_literal: true

module Storage
  class SignedUrlGenerator < ApplicationService
    DEFAULT_EXPIRES_IN = 15.minutes

    attr_reader :bucket_name, :object_key, :method, :expires_in, :content_type

    def initialize(bucket_name:, object_key:, method: :put, expires_in: DEFAULT_EXPIRES_IN, content_type: nil)
      super()
      @bucket_name = bucket_name
      @object_key = object_key
      @method = method.to_s.upcase
      @expires_in = expires_in
      @content_type = content_type
    end

    def call
      return failure("Bucket name is required") if bucket_name.blank?
      return failure("Object key is required") if object_key.blank?

      storage = Google::Cloud::Storage.new
      bucket = storage.bucket(bucket_name)

      url = bucket.signed_url(
        object_key,
        method: method,
        expires: expires_in.from_now.to_i,
        content_type: content_type,
        version: :v4,
      )

      success(url: url, object_key: object_key)
    rescue StandardError => e
      failure(e.message)
    end
  end
end
