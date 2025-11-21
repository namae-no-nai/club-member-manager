# Fingerprint Integration - Quick Reference

## TL;DR - What You Need to Know

### Registration (Store Fingerprint)
```
SDK Init → Capture Image → Create Template → Store 400 bytes → Done
```

### Verification (Check Fingerprint)
```
SDK Init → Capture Image → Create Template → Match with Stored → Return Result
```

---

## SDK Method Call Sequence

### Registration Flow

```
┌─────────────────────────────────────────────────────────┐
│ REGISTRATION: Store Fingerprint for Partner            │
└─────────────────────────────────────────────────────────┘

1. SDK Initialization
   ├─ Create()                    → Create SDK instance
   ├─ Init(SG_DEV_AUTO)           → Auto-detect device
   └─ OpenDevice(0)                → Open first device

2. Device Setup
   ├─ GetDeviceInfo()              → Get width/height
   └─ SetLedOn(True)               → Turn LED on

3. Capture
   └─ GetImage(buffer)             → Capture fingerprint image
       ↓
   └─ GetImageQuality()            → Check quality (0-100)
       ↓
   └─ CreateSG400Template()        → Create 400-byte template

4. Storage
   └─ Save template to database    → Store encrypted 400 bytes

5. Cleanup
   ├─ SetLedOn(False)              → Turn LED off
   ├─ CloseDevice()                → Close device
   └─ Terminate()                  → Cleanup SDK
```

### Verification Flow

```
┌─────────────────────────────────────────────────────────┐
│ VERIFICATION: Check if Fingerprint Matches Partner     │
└─────────────────────────────────────────────────────────┘

1. SDK Initialization (same as registration)
   ├─ Create()
   ├─ Init(SG_DEV_AUTO)
   └─ OpenDevice(0)

2. Capture Current Fingerprint (same as registration)
   ├─ GetDeviceInfo()
   ├─ SetLedOn(True)
   ├─ GetImage(buffer)
   └─ CreateSG400Template()        → Current template

3. Load Stored Template
   └─ Load from database            → Partner's stored template

4. Match
   ├─ MatchTemplate()               → Boolean match (true/false)
   └─ OR GetMatchingScore()        → Score (0-1000)

5. Return Result
   └─ { verified: true/false }

6. Cleanup (same as registration)
   ├─ SetLedOn(False)
   ├─ CloseDevice()
   └─ Terminate()
```

---

## Data Storage Cheat Sheet

### What to Store

| Data | Type | Size | Required? | Encrypted? |
|------|------|------|-----------|------------|
| **Template** | Binary | 400 bytes | ✅ YES | ✅ YES |
| Quality Score | Integer | 4 bytes | ⚠️ Recommended | ❌ No |
| Device Info | JSON | ~100 bytes | ⚠️ Recommended | ❌ No |
| Timestamp | DateTime | 8 bytes | ⚠️ Recommended | ❌ No |
| Raw Image | Binary | 50-200 KB | ❌ NO | N/A |

### Database Schema

```ruby
# Migration
add_column :partners, :fingerprint_template, :binary  # 400 bytes - REQUIRED
add_column :partners, :fingerprint_quality, :integer  # Optional
add_column :partners, :fingerprint_registered_at, :datetime  # Optional
add_column :partners, :fingerprint_device_info, :json  # Optional

# Model
class Partner < ApplicationRecord
  encrypts :fingerprint_template  # Encrypt the template
end
```

---

## Encryption Decision Tree

```
Do I need to encrypt fingerprint templates?
│
├─ YES ✅
│  │
│  └─ Use Lockbox (already configured)
│     │
│     └─ encrypts :fingerprint_template
│
└─ Why?
   ├─ Biometric data is sensitive
   ├─ Legal compliance (GDPR, etc.)
   └─ Security best practice
```

---

## Method Reference

### Initialization Methods
- `Create()` → Returns error code (0 = success)
- `Init(device_name)` → `SG_DEV_AUTO` (0xFF) for auto-detect
- `OpenDevice(device_id)` → `0` for first device
- `GetDeviceInfo()` → Returns width, height

### Capture Methods
- `SetLedOn(true/false)` → Visual feedback
- `GetImage(buffer)` → Captures image (blocking)
- `GetImageQuality()` → Returns 0-100 score

### Template Methods
- `CreateSG400Template(image, template)` → Creates 400-byte template
- `MatchTemplate(t1, t2, security_level, matched)` → Boolean match
- `GetMatchingScore(t1, t2, score)` → Returns 0-1000 score

### Cleanup Methods
- `CloseDevice()` → Close device
- `Terminate()` → Cleanup SDK

---

## Error Codes (Most Common)

| Code | Constant | Meaning |
|------|----------|---------|
| 0 | `SGFDX_ERROR_NONE` | ✅ Success |
| 54 | `SGFDX_ERROR_TIME_OUT` | ⏱️ No finger detected |
| 55 | `SGFDX_ERROR_DEVICE_NOT_FOUND` | 🔌 Device not connected |
| 62 | `SGFDX_ERROR_FAKE_FINGER` | 🚫 Fake finger detected |
| 101 | `SGFDX_ERROR_FEAT_NUMBER` | 📉 Too few features |
| 105 | `SGFDX_ERROR_EXTRACT_FAIL` | ❌ Template creation failed |

---

## Security Levels

| Level | Constant | Use Case |
|-------|----------|----------|
| 3 | `SL_LOW` | Testing, lenient |
| 5 | `SL_NORMAL` | ✅ **Recommended** |
| 7 | `SL_HIGH` | High security |
| 9 | `SL_HIGHEST` | Maximum security |

**Recommendation**: Start with `SL_NORMAL` (5), adjust based on false accept/reject rates.

---

## Common Patterns

### Pattern 1: Registration with Quality Check

```ruby
# Capture
image = sdk.get_image(size)
quality = sdk.get_image_quality(width, height, image)

# Reject if quality too low
raise "Quality too low: #{quality}" if quality < 50

# Create template
template = sdk.create_template(image)

# Store
partner.update!(fingerprint_template: template, fingerprint_quality: quality)
```

### Pattern 2: Verification with Score

```ruby
# Capture current
current_template = sdk.create_template(sdk.get_image(size))

# Load stored
stored_template = partner.fingerprint_template

# Match
score = sdk.get_matching_score(current_template, stored_template)

# Threshold (adjust based on testing)
verified = score >= 500  # 50% match threshold
```

### Pattern 3: 1:N Search

```ruby
current_template = capture_and_create_template

Partner.find_each do |partner|
  next unless partner.fingerprint_template
  
  if match?(current_template, partner.fingerprint_template)
    return { verified: true, partner: partner }
  end
end

{ verified: false }
```

---

## Decision Checklist

Before implementing, decide:

- [ ] **Device Model**: Which SecuGen device? (affects library selection)
- [ ] **Storage Location**: Column vs separate table vs attachment?
- [ ] **Encryption**: Lockbox column encryption? (recommended: YES)
- [ ] **Quality Threshold**: Minimum quality score? (recommended: 50)
- [ ] **Security Level**: Which level? (recommended: SL_NORMAL = 5)
- [ ] **Matching Method**: Boolean match vs score? (both useful)
- [ ] **1:N Search**: Need to search all partners? (performance consideration)
- [ ] **Multiple Templates**: Allow multiple fingerprints per partner? (separate table)

---

## Next Implementation Steps

1. ✅ **Understand SDK workflow** (this document)
2. ⏭️ **Create Ruby FFI wrapper** (wrap C library)
3. ⏭️ **Create database migration** (add columns)
4. ⏭️ **Implement registration service** (capture + store)
5. ⏭️ **Implement verification service** (capture + match)
6. ⏭️ **Add controller actions** (HTTP API)
7. ⏭️ **Add UI** (fingerprint capture interface)
8. ⏭️ **Test with device** (end-to-end testing)

---

## Quick Answers

**Q: What's the minimum data I need to store?**  
A: Just the 400-byte template. Everything else is optional.

**Q: Do I need to store the raw image?**  
A: No. Templates are sufficient and more secure.

**Q: How do I know if registration was successful?**  
A: Check that `CreateSG400Template()` returns `SGFDX_ERROR_NONE` and quality >= 50.

**Q: How do I know if verification matched?**  
A: `MatchTemplate()` returns `matched = true` OR `GetMatchingScore()` returns score >= threshold.

**Q: Can I use the same SDK instance for multiple operations?**  
A: Yes, but close/terminate between operations to avoid resource leaks.

**Q: What if the device isn't connected?**  
A: `OpenDevice()` will return `SGFDX_ERROR_DEVICE_NOT_FOUND` (55).

**Q: What if the image quality is too low?**  
A: `GetImageQuality()` returns score < 50. Ask user to try again with better finger placement.

**Q: Can I match templates from different devices?**  
A: Yes, templates are device-independent (same format).

**Q: How fast is matching?**  
A: Very fast - comparing 400 bytes, typically < 10ms per match.

**Q: Can I store multiple templates per partner?**  
A: Yes, use a separate `fingerprint_templates` table with `has_many` relationship.


