# Launchpad

A minimalist productivity timer built with Flutter.

## Release Signing

The CI workflow signs release APKs with a real certificate if GitHub secrets are configured, otherwise falls back to a temporary self-signed keystore (which will show a warning on install).

### Setup a real signing certificate

Generate a keystore (one time only):

```bash
keytool -genkey -v -keystore release.keystore \
  -alias release -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass <store-password> -keypass <key-password> \
  -dname "CN=YourName, OU=YourUnit, O=YourOrg, L=YourCity, ST=YourState, C=YourCountryCode"
```

Base64-encode it for GitHub Secrets:

```bash
base64 -w0 release.keystore  # macOS: base64 -b0 release.keystore
```

### GitHub Secrets

In your repository settings (**Settings → Secrets and variables → Actions**), add these secrets:

| Secret | Value |
|---|---|
| `STORE_FILE_B64` | Base64-encoded content of `release.keystore` |
| `STORE_PASSWORD` | Keystore password (same as `-storepass` above) |
| `KEY_PASSWORD` | Key password (same as `-keypass` above) |
| `KEY_ALIAS` | Key alias (default: `release`) |

Once set, all future release builds in CI will be signed with your real certificate.
