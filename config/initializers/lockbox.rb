Lockbox.master_key = ENV.fetch("LOCKBOX_ENCRYPTION_KEY") do
  raise "LOCKBOX_MASTER_KEY environment variable is not set"
end
