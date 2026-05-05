# Contributing

Thanks for considering a contribution.

## Development

Requirements:

- macOS 13 or newer
- Swift 5.9 or newer

Build and run:

```sh
make build
make run
```

Package a local app bundle:

```sh
make package
open .build/EgressBar.app
```

## Pull Requests

- Keep changes focused.
- Run `swift build` before opening a pull request.
- Update `README.md` when user-visible behavior changes.
- Do not commit API tokens, screenshots with real public IP addresses, or local
  machine paths.
