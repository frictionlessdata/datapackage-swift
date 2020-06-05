all: build

build:
	echo "public struct Version { public static var long: String { return \""`git describe --tags --dirty --long --always`"\" } }" > Sources/CommandLineInterface/Version.swift
	swift build -c release --product datapackage-swift

test:
	swift test --enable-code-coverage

install:
	cp `swift build -c release --show-bin-path`/datapackage-swift /usr/local/bin/

clean:
	rm -rf ./.build/
	rm Package.resolved
