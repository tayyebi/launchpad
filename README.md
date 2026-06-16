# Launchpad

A minimalist productivity timer built with Flutter.

## Release Signing

The CI workflow signs release APKs with a real certificate if GitHub secrets are configured, otherwise falls back to a temporary self-signed keystore (which will show a warning on install).

### Setup a real signing certificate

Generate a keystore (one time only) using OpenSSL:

```bash
# Generate a private key
openssl genrsa -out release.key 2048

# Generate a self-signed certificate (valid for 10000 days)
openssl req -x509 -new -nodes -key release.key \
  -sha256 -days 10000 -out release.crt \
  -subj "/C=YourCountryCode/ST=YourState/L=YourCity/O=YourOrg/OU=YourUnit/CN=YourName"

# Create a PKCS12 keystore (enter a keystore password when prompted)
openssl pkcs12 -export -in release.crt -inkey release.key \
  -name release -out release.p12

# Convert to JKS keystore (requires Java, otherwise use the .p12 directly)
# keytool -importkeystore -srckeystore release.p12 -srcstoretype PKCS12 \
#   -destkeystore release.keystore -deststoretype JKS
```

The `.p12` file can be used directly as the keystore.

Base64-encode it for GitHub Secrets:

```bash
base64 -w0 release.p12       # Linux
base64 -b0 release.p12       # macOS
```

### GitHub Secrets

In your repository settings (**Settings → Secrets and variables → Actions**), add these secrets:

| Secret | Value |
|---|---|
| `STORE_FILE_B64` | Base64-encoded content of `release.p12` |
| `STORE_PASSWORD` | Keystore password (the one you entered above) |
| `KEY_PASSWORD` | Same as `STORE_PASSWORD` (or a different key password if set) |
| `KEY_ALIAS` | Key alias set with `-name` above (default: `release`) |

Once set, all future release builds in CI will be signed with your real certificate.
