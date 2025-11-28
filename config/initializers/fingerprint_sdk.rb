# frozen_string_literal: true

# Set LD_LIBRARY_PATH for SecuGen fingerprint SDK libraries
# This must be set before any FFI libraries are loaded
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
end


