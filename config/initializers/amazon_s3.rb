if Railscollab.config.attach_to_s3
  Paperclip::Attachment.default_options.update(
    :storage => :s3,
    :s3_credentials => Railscollab.config.amazon_s3
  )
end