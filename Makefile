.PHONY: build run package clean

build:
	swift build

run:
	swift run EgressBar

package:
	./scripts/package-app.sh

clean:
	swift package clean
