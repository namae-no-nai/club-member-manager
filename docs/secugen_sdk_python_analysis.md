# SecuGen FDx SDK Pro - Python Integration Analysis

## Overview

This document provides a comprehensive analysis of the SecuGen FDx SDK Pro v4.0.0 for Linux, focusing on Python integration for fingerprint reader implementation.

---

## SDK Version & Platform

- **Version**: 4.0.0
- **Platform**: Linux Kernel 4 (x64)
- **Release Date**: February 17, 2022
- **Tested On**: Ubuntu 18.04, Linux generic 5.4.0-96-generic

---

## Supported Devices

The SDK supports the following SecuGen fingerprint readers:

| Device Model | VID | PID | Device Class |
|-------------|-----|-----|--------------|
| USB Hamster Air | 0x1162 | 0x2500 | U-Air (FDU10A) |
| USB Hamster PRO 30 | 0x1162 | 0x2410 | U30A (FDU09A) |
| USB Hamster PRO 20AP | 0x1162 | 0x2360 | U20AP (FDU08A) |
| USB Hamster PRO 20 | 0x1162 | 0x2240 | U20A (FDU08) |
| USB Hamster PRO 10 | 0x1162 | 0x2203 | U10 (FDU07) |
| USB Hamster PRO | 0x1162 | 0x2201 | UPx (FDU06) |
| USB Hamster PRO 20 | 0x1162 | 0x2200 | U20 (FDU05) |
| USB Hamster IV | 0x1162 | 0x2000 | SDU04P (FDU04) |
| USB Hamster Plus | 0x1162 | 0x1000 | SDU03P (FDU03) |
| USB Hamster IV | 0x1162 | 0x330 | FDU04 |
| USB Hamster Plus | 0x1162 | 0x322 | SDU03M |
| USB Hamster Plus | 0x1162 | 0x320 | FDU03 |

**Note**: Use `SG_DEV_AUTO` (0xFF) to auto-detect the connected device.

---

## System Requirements & Installation

### Prerequisites

1. **Required Packages**:
   ```bash
   libgtk2.0-dev (2.24.23-0ubuntu1)
   ```

2. **USB Device Drivers**:
   ```bash
   cd <install_dir>/lib/linux4X64
   make uninstall install
   ```

3. **User Permissions** (for non-root access):
   - Create SecuGen group: `# groupadd SecuGen`
   - Add users: `# gpasswd -a myUserID SecuGen`
   - Create udev rules in `/etc/udev/rules.d/99SecuGen.rules`
   - Reboot system

### Python Library Configuration

**Critical**: Python applications require the driver library to be statically linked to `libpysgfplib.so`. The default configuration is for U20-A.

**To configure for a specific device**:
```bash
cd <install_dir>/lib/linux4X64
# Example for Hamster Air:
cp libpysgfplib.so.4.0.0.fdu10a libpysgfplib.so.4.0.0
make uninstall install
```

**Available device-specific libraries**:
- `libpysgfplib.so.4.0.0.fdu03` - Hamster Plus
- `libpysgfplib.so.4.0.0.fdu04` - Hamster IV
- `libpysgfplib.so.4.0.0.fdu05` - U20
- `libpysgfplib.so.4.0.0.fdu06` - UPx
- `libpysgfplib.so.4.0.0.fdu07` - U10
- `libpysgfplib.so.4.0.0.fdu08` - U20A
- `libpysgfplib.so.4.0.0.fdu08a` - U20AP
- `libpysgfplib.so.4.0.0.fdu09a` - U30
- `libpysgfplib.so.4.0.0.fdu10a` - U-Air

---

## Python API Structure

### Library Location

The Python wrapper library is located at:
- **Default**: `/usr/local/lib/libpysgfplib.so`
- **Python wrapper class**: `PYSGFPLib` in `pysgfplib.py`

### Core Python Module Structure

```
python/
├── __init__.py
├── pysgfplib.py          # Main wrapper class
├── sgfdxerrorcode.py     # Error code constants
├── sgfdxdevicename.py    # Device name constants
├── sgfdxsecuritylevel.py # Security level constants
├── sgfplibtest.py        # Basic test sample
├── autoon.py             # Auto-on event sample
├── run.sh                # Test runner script
└── run_autoon.sh         # Auto-on test runner
```

---

## Python API Methods

### Initialization & Lifecycle

```python
from pysgfplib import PYSGFPLib
from sgfdxdevicename import SGFDxDeviceName
from sgfdxerrorcode import SGFDxErrorCode

sgfplib = PYSGFPLib()

# 1. Create SDK instance
result = sgfplib.Create()
# Returns: SGFDX_ERROR_NONE (0) on success

# 2. Initialize with device
result = sgfplib.Init(SGFDxDeviceName.SG_DEV_AUTO)
# Returns: SGFDX_ERROR_NONE (0) on success

# 3. Open device (0 = first device)
result = sgfplib.OpenDevice(0)
# Returns: SGFDX_ERROR_NONE (0) on success

# 4. Close device
result = sgfplib.CloseDevice()

# 5. Terminate SDK
result = sgfplib.Terminate()
```

### Device Information

```python
from ctypes import c_int, byref

# Get device info (image dimensions)
cImageWidth = c_int(0)
cImageHeight = c_int(0)
result = sgfplib.GetDeviceInfo(byref(cImageWidth), byref(cImageHeight))

print(f"Image Width: {cImageWidth.value}")
print(f"Image Height: {cImageHeight.value}")
```

### Image Capture

```python
from ctypes import c_char

# Capture fingerprint image
image_size = cImageWidth.value * cImageHeight.value
cImageBuffer = (c_char * image_size)()
result = sgfplib.GetImage(cImageBuffer)

if result == SGFDxErrorCode.SGFDX_ERROR_NONE:
    # Image captured successfully
    image_data = bytes(cImageBuffer)
    # Save or process image_data
```

### Image Quality Assessment

```python
from ctypes import c_int, byref

cQuality = c_int(0)
result = sgfplib.GetImageQuality(
    cImageWidth.value, 
    cImageHeight.value, 
    cImageBuffer, 
    byref(cQuality)
)

print(f"Image Quality: {cQuality.value}")
# Quality range: 0-100 (higher is better)
```

### Template Creation (SG400 Format)

```python
from ctypes import c_char

# SG400 template size is 400 bytes
constant_sg400_template_size = 400
cMinutiaeBuffer = (c_char * constant_sg400_template_size)()

result = sgfplib.CreateSG400Template(cImageBuffer, cMinutiaeBuffer)

if result == SGFDxErrorCode.SGFDX_ERROR_NONE:
    template_data = bytes(cMinutiaeBuffer)
    # Store template_data for matching
```

### Template Matching

```python
from ctypes import c_bool, byref
from sgfdxsecuritylevel import SGFDxSecurityLevel

# Match two templates
cMatched = c_bool(False)
result = sgfplib.MatchTemplate(
    cMinutiaeBuffer1, 
    cMinutiaeBuffer2, 
    SGFDxSecurityLevel.SL_NORMAL, 
    byref(cMatched)
)

if cMatched.value:
    print("Fingerprints MATCH")
else:
    print("Fingerprints DO NOT MATCH")
```

### Matching Score

```python
from ctypes import c_int, byref

# Get matching score (0-1000, higher = better match)
cScore = c_int(0)
result = sgfplib.GetMatchingScore(
    cMinutiaeBuffer1, 
    cMinutiaeBuffer2, 
    byref(cScore)
)

print(f"Matching Score: {cScore.value}")
```

### LED Control

```python
# Turn LED on
result = sgfplib.SetLedOn(True)

# Turn LED off
result = sgfplib.SetLedOn(False)
```

### Auto-On Event (Device-Specific)

**Note**: Only works with FDU05 and later devices (not FDU03/FDU04).

```python
import time

# Enable auto-on event detection
result = sgfplib.EnableAutoOnEvent(True)

# Check if finger is present
if sgfplib.FingerPresent():
    print("Finger detected on sensor")
    # Capture image
    result = sgfplib.GetImage(cImageBuffer)

# Disable auto-on event
result = sgfplib.EnableAutoOnEvent(False)
```

### Callback Function (Advanced)

```python
# Set callback function for live capture or auto-on events
result = sgfplib.SetCallBackFunction()
# Note: Implementation details may vary
```

---

## Error Codes

Key error codes from `sgfdxerrorcode.py`:

| Code | Constant | Description |
|------|----------|-------------|
| 0 | `SGFDX_ERROR_NONE` | Success |
| 1 | `SGFDX_ERROR_CREATION_FAILED` | SDK creation failed |
| 2 | `SGFDX_ERROR_FUNCTION_FAILED` | Function execution failed |
| 3 | `SGFDX_ERROR_INVALID_PARAM` | Invalid parameter |
| 51 | `SGFDX_ERROR_SYSLOAD_FAILED` | System file load failed |
| 52 | `SGFDX_ERROR_INITIALIZE_FAILED` | Device initialization failed |
| 54 | `SGFDX_ERROR_TIME_OUT` | Operation timeout |
| 55 | `SGFDX_ERROR_DEVICE_NOT_FOUND` | Device not found |
| 57 | `SGFDX_ERROR_WRONG_IMAGE` | Invalid image data |
| 61 | `SGFDX_ERROR_UNSUPPORTED_DEV` | Unsupported device |
| 62 | `SGFDX_ERROR_FAKE_FINGER` | Fake finger detected |
| 101 | `SGFDX_ERROR_FEAT_NUMBER` | Too few minutiae |
| 105 | `SGFDX_ERROR_EXTRACT_FAIL` | Template extraction failed |
| 106 | `SGFDX_ERROR_MATCH_FAIL` | Template matching failed |

---

## Security Levels

From `sgfdxsecuritylevel.py`:

| Level | Constant | Description |
|-------|----------|-------------|
| 0 | `SL_NONE` | No security (not recommended) |
| 1 | `SL_LOWEST` | Lowest security |
| 2 | `SL_LOWER` | Lower security |
| 3 | `SL_LOW` | Low security |
| 4 | `SL_BELOW_NORMAL` | Below normal |
| 5 | `SL_NORMAL` | Normal (recommended default) |
| 6 | `SL_ABOVE_NORMAL` | Above normal |
| 7 | `SL_HIGH` | High security |
| 8 | `SL_HIGHER` | Higher security |
| 9 | `SL_HIGHEST` | Highest security |

**Recommendation**: Use `SL_NORMAL` (5) for most applications. Higher levels reduce false acceptance but may increase false rejection.

---

## Template Formats

The SDK supports multiple template formats:

1. **SG400** (SecuGen proprietary)
   - Default format
   - Typically 400 bytes
   - Fast matching
   - Use: `CreateSG400Template()`

2. **ANSI378** (ANSI-INCITS 378-2004)
   - Standard format
   - Interoperable with other systems
   - Not directly exposed in Python wrapper (C API only)

3. **ISO19794-2** (ISO/IEC 19794-2:2005)
   - International standard
   - Not directly exposed in Python wrapper (C API only)

**Note**: The Python wrapper (`pysgfplib.py`) only exposes SG400 template creation. For ANSI/ISO formats, you would need to use the C API directly or extend the Python wrapper.

---

## Complete Workflow Example

```python
#!/usr/bin/env python
from pysgfplib import PYSGFPLib
from sgfdxdevicename import SGFDxDeviceName
from sgfdxerrorcode import SGFDxErrorCode
from sgfdxsecuritylevel import SGFDxSecurityLevel
from ctypes import *

# Initialize SDK
sgfplib = PYSGFPLib()

# 1. Create SDK instance
if sgfplib.Create() != SGFDxErrorCode.SGFDX_ERROR_NONE:
    print("Failed to create SDK")
    exit(1)

# 2. Initialize with auto-detect
if sgfplib.Init(SGFDxDeviceName.SG_DEV_AUTO) != SGFDxErrorCode.SGFDX_ERROR_NONE:
    print("Failed to initialize SDK")
    sgfplib.Terminate()
    exit(1)

# 3. Open device
if sgfplib.OpenDevice(0) != SGFDxErrorCode.SGFDX_ERROR_NONE:
    print("Failed to open device")
    sgfplib.Terminate()
    exit(1)

# 4. Get device info
cImageWidth = c_int(0)
cImageHeight = c_int(0)
sgfplib.GetDeviceInfo(byref(cImageWidth), byref(cImageHeight))
print(f"Device: {cImageWidth.value}x{cImageHeight.value}")

# 5. Turn LED on
sgfplib.SetLedOn(True)

# 6. Capture image
image_size = cImageWidth.value * cImageHeight.value
cImageBuffer = (c_char * image_size)()
result = sgfplib.GetImage(cImageBuffer)

if result == SGFDxErrorCode.SGFDX_ERROR_NONE:
    # 7. Check image quality
    cQuality = c_int(0)
    sgfplib.GetImageQuality(
        cImageWidth.value, 
        cImageHeight.value, 
        cImageBuffer, 
        byref(cQuality)
    )
    print(f"Image Quality: {cQuality.value}")
    
    # 8. Create template
    cMinutiaeBuffer = (c_char * 400)()
    result = sgfplib.CreateSG400Template(cImageBuffer, cMinutiaeBuffer)
    
    if result == SGFDxErrorCode.SGFDX_ERROR_NONE:
        template = bytes(cMinutiaeBuffer)
        print(f"Template created: {len(template)} bytes")
        # Store template for later matching
    else:
        print("Template creation failed")
else:
    print("Image capture failed")

# 9. Turn LED off
sgfplib.SetLedOn(False)

# 10. Cleanup
sgfplib.CloseDevice()
sgfplib.Terminate()
```

---

## Key Limitations & Considerations

### 1. Device-Specific Features

- **Auto-On Event**: Only available on FDU05 and later (not FDU03/FDU04)
- **Fake Detection**: Available on U10, U20-A, and U20-AP devices
- **Template Formats**: Python wrapper only exposes SG400; ANSI/ISO require C API

### 2. Library Linking

- Python library must be statically linked to device-specific driver
- Must configure correct library before installation
- Default is U20-A; change for other devices

### 3. Permissions

- Requires root or SecuGen group membership
- USB device access requires udev rules configuration
- System reboot required after udev rule changes

### 4. Thread Safety

- SDK may not be thread-safe
- Use single instance per process
- Consider locking for concurrent access

### 5. Error Handling

- Always check return codes
- `SGFDX_ERROR_NONE` (0) indicates success
- Handle timeout errors (`SGFDX_ERROR_TIME_OUT`)
- Check for fake finger detection (`SGFDX_ERROR_FAKE_FINGER`)

---

## Integration with Rails

### Architecture Options

1. **Direct Python Integration**
   - Use Python subprocess calls from Ruby
   - Pass data via JSON/stdin/stdout
   - Simple but slower (process overhead)

2. **Python Service/API**
   - Create Flask/FastAPI service
   - Ruby calls via HTTP
   - Better separation, more complex

3. **Ruby FFI (Alternative)**
   - Direct C library calls from Ruby
   - No Python dependency
   - More complex, better performance

### Recommended Approach

For Rails integration, consider:

1. **Python Service** (Recommended for flexibility):
   - Create a Python service that wraps `PYSGFPLib`
   - Expose REST API endpoints
   - Rails calls service via HTTP
   - Handles device initialization, capture, matching

2. **Key Endpoints**:
   - `POST /capture` - Capture fingerprint image
   - `POST /template` - Create template from image
   - `POST /match` - Match two templates
   - `GET /device/info` - Get device information
   - `POST /device/led` - Control LED

---

## Testing & Validation

### Sample Programs

1. **Basic Test** (`sgfplibtest.py`):
   ```bash
   sudo python sgfplibtest.py
   ```
   - Tests initialization, capture, template creation, matching

2. **Auto-On Test** (`autoon.py`):
   ```bash
   sudo python autoon.py
   ```
   - Tests auto-on event detection (FDU05+ only)

### Validation Checklist

- [ ] Device detected and opened successfully
- [ ] Image capture works
- [ ] Image quality assessment works
- [ ] Template creation succeeds
- [ ] Template matching works (same finger)
- [ ] Template matching rejects different fingers
- [ ] LED control works
- [ ] Error handling works correctly
- [ ] Cleanup (CloseDevice, Terminate) works

---

## Troubleshooting

### Common Issues

1. **Library Not Found**:
   - Check `/usr/local/lib/libpysgfplib.so` exists
   - Verify library is linked to correct device driver
   - Run `ldconfig` if needed

2. **Permission Denied**:
   - User must be in SecuGen group
   - Check udev rules are installed
   - May need to run with `sudo` initially

3. **Device Not Found**:
   - Verify device is connected
   - Check USB connection
   - Verify device VID/PID matches supported devices
   - Try `SG_DEV_AUTO` for auto-detection

4. **Template Creation Fails**:
   - Check image quality (should be > 50)
   - Ensure finger is properly placed
   - Try multiple captures
   - Check for fake finger error

5. **Matching Fails**:
   - Verify security level is appropriate
   - Check template quality
   - Ensure same finger is used
   - Try lower security level for testing

---

## Next Steps for Implementation

1. **Install SDK**:
   - Install device drivers
   - Configure udev rules
   - Install Python library for target device

2. **Test Basic Functionality**:
   - Run `sgfplibtest.py` to verify SDK works
   - Test with actual fingerprint reader

3. **Design Service Architecture**:
   - Decide on integration approach (Python service vs FFI)
   - Design API endpoints
   - Plan error handling

4. **Implement Core Features**:
   - Fingerprint capture
   - Template creation
   - Template storage
   - Template matching (1:1 verification)
   - Template search (1:N identification)

5. **Integration with Rails**:
   - Create service wrapper
   - Integrate with Partner model
   - Add biometric verification endpoints
   - Implement UI for capture

---

## References

- **SDK Documentation**: `demo/FDx_SDK_PRO_LINUX4_X64_4_0_0/document/`
- **Programming Manual**: `FDx SDK Pro Programming Manual (UNIX-Linux) SG1-0034A-006.pdf`
- **Fake Detection Guide**: `SecuGen Fake Finger Detection Guide (SG1-0201A-000).pdf`
- **Sample Code**: `demo/FDx_SDK_PRO_LINUX4_X64_4_0_0/python/`
- **C API Header**: `demo/FDx_SDK_PRO_LINUX4_X64_4_0_0/include/sgfplib.h`

---

## Summary

The SecuGen FDx SDK Pro v4.0.0 provides a comprehensive Python API for fingerprint capture, template creation, and matching. The Python wrapper (`PYSGFPLib`) simplifies integration while maintaining access to core functionality. Key considerations include:

- Device-specific library configuration
- Proper error handling
- Security level selection
- Template format choice (SG400 for Python)
- Integration architecture (service vs direct)

The SDK is well-documented with sample code, making it suitable for production integration with proper testing and validation.


