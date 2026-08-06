.PHONY: all binaries package verify clean

all: package verify

binaries:
	./scripts/build-binaries.sh

package: binaries
	./scripts/package.sh

verify:
	./scripts/verify-release.sh

clean:
	rm -rf dist
