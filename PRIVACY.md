# Privacy

EgressBar is a local macOS menu bar utility. It does not run its own backend
and does not collect analytics.

## Network Requests

To determine your current public internet egress, EgressBar requests IPinfo:

- Without a token: `https://ipinfo.io/json`
- With a token: `https://api.ipinfo.io/lookup/me?token=...`

Those requests reveal your public IP address to IPinfo, and IPinfo returns
location and network metadata such as city, region, country, ASN, and ISP.

## Local Storage

The optional IPinfo token is stored in the macOS Keychain. No token is stored in
the repository or sent anywhere except IPinfo.

## Clipboard

The Copy Current IP action writes only the displayed public IP address to the
macOS pasteboard.

## Launch at Login

The Launch at Login setting uses Apple's `SMAppService` API. It does not add
third-party background services.
