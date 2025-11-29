# Native Libraries for SecuGen Fingerprint SDK

This directory contains the native shared libraries required for the SecuGen FDx SDK Pro fingerprint reader integration.

## Libraries Included

- **libsgfplib.so.4.0.1** - Main SecuGen SDK library
- **libsgimage.so.1.0.0** - Image processing library
- **libsgfpamx.so.3.7.0** - Pattern matching library
- **libsgnfiq.so.1.0.0** - Image quality assessment library
- **libAKXUS.so.2.0.11** - USB communication library
- **libuvc.so.0.0.6** - USB Video Class library
- **libsgfdu08.so.1.0.0** - Device driver for U20-A (USB Hamster PRO 20, PID 0x2240)
- **libnxsdk.so** - NextSensor SDK library (required by device drivers)

## System Dependencies

These libraries require the following system libraries (not included):
- `libjpeg.so.8` - JPEG image processing (may need to be installed or symlinked)
- `libusb-0.1.so.4` - Legacy USB library (required by device drivers)
- Standard system libraries: `libdl.so.2`, `libpthread.so.0`, `libc.so.6`, `libm.so.6`, `libusb-1.0.so.0`, `libudev.so.1`, `libcap.so.2`, `libgcc_s.so.1`, `libstdc++.so.6`

## Usage

When loading these libraries, ensure `LD_LIBRARY_PATH` includes this directory, or use `rpath` when linking.

For Ruby FFI, the library path should point to:
```
Rails.root.join("vendor", "lib", "native", "libsgfplib.so")
```

## libjpeg.so.8 Dependency

The `libuvc.so` library requires `libjpeg.so.8`. If your system has a newer version (e.g., `libjpeg.so.62`), you may need to:

1. Install a compat package (if available)
2. Create a symlink: `sudo ln -s /usr/lib64/libjpeg.so.62 /usr/lib64/libjpeg.so.8`
3. Or bundle `libjpeg.so.8` separately if you can obtain it


