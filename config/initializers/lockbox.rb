# Lockbox configuration for encrypting Active Storage attachments
Lockbox.master_key = ENV.fetch("LOCKBOX_ENCRYPTION_KEY", nil)
