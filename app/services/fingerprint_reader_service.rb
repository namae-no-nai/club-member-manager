# frozen_string_literal: true

require "ffi"

# Ruby FFI wrapper for SecuGen FDx SDK Pro
# This service provides a Ruby interface to the SecuGen fingerprint reader SDK
class FingerprintReaderService
  extend FFI::Library

  # Library path - loads from vendor folder
  # The library and its dependencies are bundled in vendor/lib/native/
  SDK_LIB_PATH = begin
    if defined?(Rails) && Rails.respond_to?(:root)
      Rails.root.join("vendor", "lib", "native", "libsgfplib.so").to_s
    else
      File.expand_path(File.join(__dir__, "..", "..", "..", "vendor", "lib", "native", "libsgfplib.so"))
    end
  end
  NATIVE_LIB_DIR = File.expand_path(File.dirname(SDK_LIB_PATH))

  # LD_LIBRARY_PATH should be set by config/initializers/fingerprint_sdk.rb
  # This ensures libsgimage.so, libsgfpamx.so, etc. are accessible
  # Preload dependencies so they're available when the main library loads
  # This ensures the dynamic linker can resolve all symbols
  DEPENDENCY_LIBS = %w[
    libuvc.so.0
    libAKXUS.so.2
    libsgnfiq.so
    libsgfpamx.so
    libsgimage.so
  ].freeze

  # Device driver libraries that need to be preloaded
  # The SDK dynamically loads these when opening a device
  DEVICE_DRIVER_LIBS = %w[
    libnxsdk.so
    libsgfdu08.so.1
  ].freeze

  # System libraries that need to be preloaded (C++ runtime and USB)
  SYSTEM_LIBS = %w[
    libstdc++.so.6
    libusb-0.1.so.4
  ].freeze

  begin
    require "fiddle"
    @_preloaded_handles ||= []

    # First, preload system libraries (C++ runtime must be loaded first)
    SYSTEM_LIBS.each do |lib_name|
      # Try common system library paths
      system_paths = [ "/usr/lib64", "/usr/lib", "/lib64", "/lib" ]
      lib_path = nil

      system_paths.each do |path|
        candidate = File.join(path, lib_name)
        if File.exist?(candidate)
          lib_path = candidate
          break
        end
      end

      next unless lib_path

      begin
        # Preload system library with RTLD_GLOBAL flag
        handle = Fiddle::Handle.new(lib_path, Fiddle::RTLD_LAZY | Fiddle::RTLD_GLOBAL)
        @_preloaded_handles << handle
        Rails.logger.debug("Preloaded system library: #{lib_path}") if defined?(Rails) && Rails.logger
      rescue Fiddle::DLError => e
        Rails.logger.warn("Failed to preload #{lib_name}: #{e.message}") if defined?(Rails) && Rails.logger
      end
    end

    # Then preload vendor dependencies
    DEPENDENCY_LIBS.each do |lib_name|
      lib_path = File.join(NATIVE_LIB_DIR, lib_name)
      next unless File.exist?(lib_path)

      begin
        # Use system dlopen to preload with RTLD_GLOBAL flag
        # This makes the library symbols available to subsequently loaded libraries
        handle = Fiddle::Handle.new(lib_path, Fiddle::RTLD_LAZY | Fiddle::RTLD_GLOBAL)
        @_preloaded_handles << handle
      rescue Fiddle::DLError => e
        Rails.logger.debug("Preloading #{lib_name} failed: #{e.message}") if defined?(Rails) && Rails.logger
      end
    end

    # Preload device driver libraries (needed when opening device)
    DEVICE_DRIVER_LIBS.each do |lib_name|
      lib_path = File.join(NATIVE_LIB_DIR, lib_name)
      next unless File.exist?(lib_path)

      begin
        # Preload device driver with RTLD_GLOBAL so SDK can find it when opening device
        handle = Fiddle::Handle.new(lib_path, Fiddle::RTLD_LAZY | Fiddle::RTLD_GLOBAL)
        @_preloaded_handles << handle
        Rails.logger.debug("Preloaded device driver: #{lib_path}") if defined?(Rails) && Rails.logger
      rescue Fiddle::DLError => e
        Rails.logger.debug("Preloading device driver #{lib_name} failed: #{e.message}") if defined?(Rails) && Rails.logger
      end
    end

    # Now load the main library
    ffi_lib SDK_LIB_PATH
  rescue LoadError => e
    if defined?(Rails) && Rails.logger
      Rails.logger.error("Failed to load SecuGen SDK library from #{SDK_LIB_PATH}: #{e.message}")
      Rails.logger.error("Please ensure the library is installed and accessible")
      Rails.logger.error("LD_LIBRARY_PATH: #{ENV['LD_LIBRARY_PATH']}")
      Rails.logger.error("NATIVE_LIB_DIR: #{NATIVE_LIB_DIR}")
    end
    raise
  end

  # Error codes
  ERROR_NONE = 0
  ERROR_CREATION_FAILED = 1
  ERROR_FUNCTION_FAILED = 2
  ERROR_INVALID_PARAM = 3
  ERROR_TIME_OUT = 54
  ERROR_DEVICE_NOT_FOUND = 55
  ERROR_WRONG_IMAGE = 57
  ERROR_FAKE_FINGER = 62
  ERROR_FEAT_NUMBER = 101
  ERROR_EXTRACT_FAIL = 105
  ERROR_MATCH_FAIL = 106

  # Device names
  DEV_AUTO = 0xFF
  DEV_FDU03 = 0x04
  DEV_FDU04 = 0x05
  DEV_FDU08 = 0x0A  # U20A
  DEV_FDU09A = 0x12 # U30
  DEV_FDU10A = 0x13 # U-Air

  # Security levels
  SL_NONE = 0
  SL_LOWEST = 1
  SL_LOWER = 2
  SL_LOW = 3
  SL_BELOW_NORMAL = 4
  SL_NORMAL = 5
  SL_ABOVE_NORMAL = 6
  SL_HIGH = 7
  SL_HIGHER = 8
  SL_HIGHEST = 9

  # Template format
  TEMPLATE_FORMAT_SG400 = 0x0200
  SG400_TEMPLATE_SIZE = 400

  # Device info structure
  class DeviceInfo < FFI::Struct
    layout(
      :device_id, :uint32,
      :device_sn, [ :uint8, 16 ],  # 15 bytes + null terminator
      :com_port, :uint32,
      :com_speed, :uint32,
      :image_width, :uint32,
      :image_height, :uint32,
      :contrast, :uint32,
      :brightness, :uint32,
      :gain, :uint32,
      :image_dpi, :uint32,
      :fw_version, :uint32
    )
  end

  # Finger info structure (for template creation)
  class FingerInfo < FFI::Struct
    layout(
      :finger_number, :uint16,
      :view_number, :uint16,
      :impression_type, :uint16,
      :image_quality, :uint16
    )
  end

  # Attach C functions
  # Note: HSGFPM is a void* pointer, represented as :pointer in FFI

  # Initialization
  attach_function :SGFPM_Create, [ :pointer ], :uint32
  attach_function :SGFPM_Terminate, [ :pointer ], :uint32
  attach_function :SGFPM_Init, [ :pointer, :uint32 ], :uint32
  attach_function :SGFPM_OpenDevice, [ :pointer, :uint32 ], :uint32
  attach_function :SGFPM_CloseDevice, [ :pointer ], :uint32

  # Device information
  # C API uses a struct, Python wrapper converts to separate pointers
  attach_function :SGFPM_GetDeviceInfo, [ :pointer, DeviceInfo.by_ref ], :uint32

  # LED control
  attach_function :SGFPM_SetLedOn, [ :pointer, :bool ], :uint32

  # Image capture
  attach_function :SGFPM_GetImage, [ :pointer, :pointer ], :uint32
  attach_function :SGFPM_GetImageQuality, [ :pointer, :uint32, :uint32, :pointer, :pointer ], :uint32

  # Template operations
  attach_function :SGFPM_CreateTemplate, [ :pointer, FingerInfo.by_ref, :pointer, :pointer ], :uint32
  attach_function :SGFPM_GetMaxTemplateSize, [ :pointer, :pointer ], :uint32

  # Matching
  attach_function :SGFPM_MatchTemplate, [ :pointer, :pointer, :pointer, :uint32, :pointer ], :uint32
  attach_function :SGFPM_GetMatchingScore, [ :pointer, :pointer, :pointer, :pointer ], :uint32

  # Instance methods
  attr_reader :handle, :device_info, :initialized

  def initialize
    @handle = nil
    @device_info = nil
    @initialized = false
  end

  # Create SDK instance
  def create
    handle_ptr = FFI::MemoryPointer.new(:pointer)
    result = SGFPM_Create(handle_ptr)

    if result == ERROR_NONE
      @handle = handle_ptr.read_pointer
      Rails.logger.info("SecuGen SDK created successfully")
      true
    else
      Rails.logger.error("Failed to create SDK: error code #{result}")
      false
    end
  end

  # Initialize with device
  def init(device_name: DEV_AUTO)
    return false unless @handle

    result = SGFPM_Init(@handle, device_name)

    if result == ERROR_NONE
      Rails.logger.info("SDK initialized with device: 0x#{device_name.to_s(16)}")
      true
    else
      Rails.logger.error("Failed to initialize SDK: error code #{result}")
      false
    end
  end

  # Open device
  def open_device(device_id: 0)
    return false unless @handle

    result = SGFPM_OpenDevice(@handle, device_id)

    if result == ERROR_NONE
      Rails.logger.info("Device opened: device_id=#{device_id}")
      @initialized = true
      true
    else
      Rails.logger.error("Failed to open device: error code #{result}")
      Rails.logger.error("LD_LIBRARY_PATH: #{ENV['LD_LIBRARY_PATH']}")
      Rails.logger.error("Device driver should be in: #{NATIVE_LIB_DIR}")
      Rails.logger.error("Check if device is connected: lsusb | grep 1162")
      Rails.logger.error("Check if user is in SecuGen group: groups | grep SecuGen")
      false
    end
  end

  # Get device information
  # Note: Struct must be properly aligned. Using FFI::Struct which handles alignment automatically.
  def get_device_info
    return nil unless @handle

    # Create a new struct instance for each call to avoid memory issues
    device_info = DeviceInfo.new

    # Zero out the struct to ensure clean state
    device_info.pointer.clear

    result = SGFPM_GetDeviceInfo(@handle, device_info)

    if result == ERROR_NONE
      # Read all fields to check what we're getting
      device_id = device_info[:device_id]
      com_port = device_info[:com_port]
      com_speed = device_info[:com_speed]
      image_width = device_info[:image_width]
      image_height = device_info[:image_height]
      contrast = device_info[:contrast]
      brightness = device_info[:brightness]
      gain = device_info[:gain]
      image_dpi = device_info[:image_dpi]
      fw_version = device_info[:fw_version]

      Rails.logger.debug("Raw DeviceInfo struct values (all fields):")
      Rails.logger.debug("  device_id: #{device_id}")
      Rails.logger.debug("  com_port: #{com_port}")
      Rails.logger.debug("  com_speed: #{com_speed}")
      Rails.logger.debug("  image_width: #{image_width} (0x#{image_width.to_s(16)})")
      Rails.logger.debug("  image_height: #{image_height} (0x#{image_height.to_s(16)})")
      Rails.logger.debug("  contrast: #{contrast}")
      Rails.logger.debug("  brightness: #{brightness}")
      Rails.logger.debug("  gain: #{gain}")
      Rails.logger.debug("  image_dpi: #{image_dpi}")
      Rails.logger.debug("  fw_version: #{fw_version} (0x#{fw_version.to_s(16)})")
      Rails.logger.debug("  Struct size: #{DeviceInfo.size} bytes")
      Rails.logger.debug("  Raw bytes (first 32): #{device_info.pointer.read_bytes([ 32, DeviceInfo.size ].min).bytes.map { |b| '0x%02x' % b }.join(' ')}")

      # For U20-A device, if dimensions are 0, use known defaults
      # U20-A typically has 256x360 or 300x400 dimensions at 400 DPI
      if image_width == 0 || image_height == 0
        Rails.logger.warn("Device returned 0x0 dimensions. Using U20-A defaults: 300x400")
        image_width = 300
        image_height = 400
      end

      @device_info = {
        device_id: device_id,
        image_width: image_width,
        image_height: image_height,
        image_dpi: image_dpi,
        brightness: brightness,
        contrast: contrast
      }

      Rails.logger.info("Device info: #{@device_info[:image_width]}x#{@device_info[:image_height]} @ #{@device_info[:image_dpi]} DPI")
      @device_info
    else
      Rails.logger.error("Failed to get device info: error code #{result}")
      nil
    end
  end

  # Set LED on/off
  def set_led_on(on: true)
    return false unless @handle

    result = SGFPM_SetLedOn(@handle, on)

    if result == ERROR_NONE
      Rails.logger.debug("LED #{on ? 'ON' : 'OFF'}")
      true
    else
      Rails.logger.error("Failed to set LED: error code #{result}")
      false
    end
  end

  # Capture fingerprint image
  # This function BLOCKS until a finger is placed on the sensor or timeout occurs
  def get_image(image_size)
    return nil unless @handle

    if image_size <= 0
      Rails.logger.error("Invalid image size: #{image_size}. Device info may not be available.")
      return nil
    end

    Rails.logger.info("Waiting for fingerprint... (this will block until finger is detected or timeout)")
    image_buffer = FFI::MemoryPointer.new(:uint8, image_size)
    result = SGFPM_GetImage(@handle, image_buffer)

    if result == ERROR_NONE
      image_data = image_buffer.read_bytes(image_size)
      Rails.logger.info("Image captured: #{image_size} bytes")
      image_data
    else
      case result
      when ERROR_TIME_OUT
        Rails.logger.error("Failed to capture image: timeout (error code #{result}). No finger detected within timeout period.")
      when ERROR_WRONG_IMAGE
        Rails.logger.error("Failed to capture image: wrong/invalid image (error code #{result}). Image size may be incorrect.")
      else
        Rails.logger.error("Failed to capture image: error code #{result}")
      end
      nil
    end
  end

  # Get image quality
  def get_image_quality(width, height, image_data)
    return nil unless @handle

    quality_ptr = FFI::MemoryPointer.new(:uint32)
    image_buffer = FFI::MemoryPointer.new(:uint8, image_data.bytesize)
    image_buffer.put_bytes(0, image_data)

    result = SGFPM_GetImageQuality(@handle, width, height, image_buffer, quality_ptr)

    if result == ERROR_NONE
      quality = quality_ptr.read_uint32
      Rails.logger.info("Image quality: #{quality}")
      quality
    else
      Rails.logger.error("Failed to get image quality: error code #{result}")
      nil
    end
  end

  # Create SG400 template from image
  def create_template(image_data, image_width: nil, image_height: nil)
    return nil unless @handle

    # Get device info if not provided
    unless image_width && image_height
      info = get_device_info
      return nil unless info
      image_width = info[:image_width]
      image_height = info[:image_height]
    end

    # Prepare image buffer
    image_buffer = FFI::MemoryPointer.new(:uint8, image_data.bytesize)
    image_buffer.put_bytes(0, image_data)

    # Prepare template buffer (400 bytes for SG400)
    template_buffer = FFI::MemoryPointer.new(:uint8, SG400_TEMPLATE_SIZE)

    # Create finger info structure
    finger_info = FingerInfo.new
    finger_info[:finger_number] = 0  # Unknown
    finger_info[:view_number] = 1
    finger_info[:impression_type] = 0  # Live-scan plain
    finger_info[:image_quality] = 0  # Will be set by SDK

    # Create template
    result = SGFPM_CreateTemplate(@handle, finger_info, image_buffer, template_buffer)

    if result == ERROR_NONE
      template_data = template_buffer.read_bytes(SG400_TEMPLATE_SIZE)
      Rails.logger.info("Template created: #{template_data.bytesize} bytes")
      template_data
    else
      Rails.logger.error("Failed to create template: error code #{result}")
      case result
      when ERROR_FEAT_NUMBER
        Rails.logger.error("Too few minutiae points in image")
      when ERROR_EXTRACT_FAIL
        Rails.logger.error("Template extraction failed")
      end
      nil
    end
  end

  # Match two templates (returns boolean)
  def match_template(template1, template2, security_level: SL_NORMAL)
    return { matched: false, error: "SDK not initialized" } unless @handle

    # Prepare template buffers
    template1_buffer = FFI::MemoryPointer.new(:uint8, template1.bytesize)
    template1_buffer.put_bytes(0, template1)

    template2_buffer = FFI::MemoryPointer.new(:uint8, template2.bytesize)
    template2_buffer.put_bytes(0, template2)

    # Prepare matched output
    matched_ptr = FFI::MemoryPointer.new(:int)
    matched_ptr.write_int(0)

    result = SGFPM_MatchTemplate(@handle, template1_buffer, template2_buffer, security_level, matched_ptr)

    if result == ERROR_NONE
      matched = matched_ptr.read_int != 0
      Rails.logger.info("Template match result: #{matched}")
      { matched: matched, error: nil }
    else
      Rails.logger.error("Template matching failed: error code #{result}")
      { matched: false, error: "Matching failed: error code #{result}" }
    end
  end

  # Get matching score (returns 0-1000)
  def get_matching_score(template1, template2)
    return { score: 0, error: "SDK not initialized" } unless @handle

    # Prepare template buffers
    template1_buffer = FFI::MemoryPointer.new(:uint8, template1.bytesize)
    template1_buffer.put_bytes(0, template1)

    template2_buffer = FFI::MemoryPointer.new(:uint8, template2.bytesize)
    template2_buffer.put_bytes(0, template2)

    # Prepare score output
    score_ptr = FFI::MemoryPointer.new(:uint32)
    score_ptr.write_uint32(0)

    result = SGFPM_GetMatchingScore(@handle, template1_buffer, template2_buffer, score_ptr)

    if result == ERROR_NONE
      score = score_ptr.read_uint32
      Rails.logger.info("Matching score: #{score}")
      { score: score, error: nil }
    else
      Rails.logger.error("Failed to get matching score: error code #{result}")
      { score: 0, error: "Failed: error code #{result}" }
    end
  end

  # Close device
  def close_device
    return false unless @handle

    result = SGFPM_CloseDevice(@handle)

    if result == ERROR_NONE
      Rails.logger.info("Device closed")
      @initialized = false
      true
    else
      Rails.logger.error("Failed to close device: error code #{result}")
      false
    end
  end

  # Terminate SDK
  def terminate
    return false unless @handle

    result = SGFPM_Terminate(@handle)

    if result == ERROR_NONE
      Rails.logger.info("SDK terminated")
      @handle = nil
      @initialized = false
      true
    else
      Rails.logger.error("Failed to terminate SDK: error code #{result}")
      false
    end
  end

  # Cleanup (convenience method)
  def cleanup
    set_led_on(on: false) if @initialized
    close_device
    terminate
  end
end
