# frozen_string_literal: true

# Set LD_LIBRARY_PATH for SecuGen fingerprint SDK libraries
# This must be set before any FFI libraries are loaded.
#
# Note: Setting ENV["LD_LIBRARY_PATH"] at runtime may not affect the dynamic
# linker if it has already been initialized. This initializer runs before app
# code is loaded, which should work, but if you encounter library loading
# errors, you may need to set LD_LIBRARY_PATH before starting Rails:
#
#   export LD_LIBRARY_PATH=/path/to/vendor/lib/native:$LD_LIBRARY_PATH
#   rails console
#
if defined?(Rails) && Rails.respond_to?(:root)
  native_lib_dir = Rails.root.join("vendor", "lib", "native").to_s
else
  native_lib_dir = File.expand_path(File.join(__dir__, "..", "..", "vendor", "lib", "native"))
end

if File.directory?(native_lib_dir)
  existing_path = ENV["LD_LIBRARY_PATH"] || ""
  path_parts = existing_path.split(":").reject(&:empty?)
  
  # Add vendor lib directory first (highest priority)
  unless path_parts.include?(native_lib_dir)
    path_parts.unshift(native_lib_dir)
  end
  
  # Also add /usr/local/lib so SDK can find device drivers and data files
  # The SDK may look for drivers in /usr/local/lib when opening device
  unless path_parts.include?("/usr/local/lib")
    path_parts << "/usr/local/lib"
  end
  
  # Add /usr/lib64 for system libraries like libusb-0.1.so.4
  # This is needed by device drivers
  unless path_parts.include?("/usr/lib64")
    path_parts << "/usr/lib64"
  end
  
  ENV["LD_LIBRARY_PATH"] = path_parts.join(":")
  
  Rails.logger.debug("Fingerprint SDK: LD_LIBRARY_PATH set to #{ENV['LD_LIBRARY_PATH']}") if defined?(Rails) && Rails.logger
end


