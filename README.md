# EgressBar

EgressBar is a native macOS menu bar utility that shows where your current
public internet traffic exits: city, region, country, IP address, ASN, and ISP.

It is useful when switching VPNs, proxies, Wi-Fi networks, or cloud workspaces
and you want a quick sanity check from the menu bar.

## Requirements

- macOS 13 or newer
- Swift 5.9 or newer

## Features

- Menu bar title like `Los Angeles, California, US`
- Menu details for IP, network status, location, country, city, region, ASN,
  ISP, and last updated time
- Manual refresh
- Ten-minute automatic refresh
- Network-change refresh via `NWPathMonitor`
- Copy current IP to the pasteboard
- Optional Launch at Login toggle
- Optional IPinfo token stored in the macOS Keychain

## Development

Build:

```sh
make build
```

Run from source:

```sh
make run
```

## Package an App Bundle

```sh
make package
open .build/EgressBar.app
```

Use the packaged app for the Launch at Login toggle. `make run` is intended for
development.

The default bundle identifier is `com.amazing.egressbar`. For your own release
builds, override it at package time:

```sh
BUNDLE_ID=com.example.egressbar make package
```

## IPinfo

Without a token, EgressBar uses:

```text
https://ipinfo.io/json
```

With a token, EgressBar uses:

```text
https://api.ipinfo.io/lookup/me?token=...
```

You can set the token in Settings. Development builds may also read
`IPINFO_TOKEN` from the environment when no Keychain token has been saved.

## Privacy

EgressBar does not collect analytics and does not run its own backend. It sends
requests to IPinfo so IPinfo can return your public egress location and network
metadata. See [PRIVACY.md](PRIVACY.md) for details.

## Screenshots

Screenshots should be captured from a packaged build. Avoid publishing images
that include a real personal IP address or precise home/work location; redact
those values or use a test network.

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).
