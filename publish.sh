#!/bin/bash
set -euo pipefail

function usage() {
	cat <<EOF
Addon publishing script; currently very rudimentary

-h, --help      - Print help and exit
-i, --icon      - Update icon shown in Steam Workshop (icon512.jpg)
-p, --package   - Update .gma package (automatically packages first)

EOF
	exit 1
}

# parse args

DOPACKAGE=""
DOICON=""

while [[ $# -gt 0 ]]; do
key="$1"

case $key in
	-h|--help)
		usage
	;;
	-i|--icon)
		DOICON=true
		shift # past argument
	;;
	-p|--package)
		DOPACKAGE=true
		shift # past argument
	;;
	*)	# unknown option
		echo "Unknown option: '$1'"
		usage
	;;
esac
done

# quick exit if nothing to do

if [[ ! ( $DOPACKAGE ) && ! ( $DOICON ) ]]; then
	echo "$0: Nothing to do."
	echo ""
	usage
fi

# set up

REPO_DIR=$(dirname "$(realpath $0)")

cd "$REPO_DIR"

ARGLIST=""

# handle icon publishing params
if [[ $DOICON ]]; then
	ARGLIST="-icon icon512.jpg $ARGLIST"
fi

# handle package publishing params
GMA_FILE="$(basename "$REPO_DIR").gma"
if [[ $DOPACKAGE ]]; then
	#first, do packaging
	./package.sh || {
		echo "Packaging failed; cannot publish! Please fix packaging and try again"
		exit 1
	}
	ARGLIST="-addon ..\\$GMA_FILE $ARGLIST"
fi

# do the publish

winpty ../../../bin/gmpublish.exe update -id "1555099832" $ARGLIST

# clean up

if [[ $DOPACKAGE ]]; then
	GMA_FILE="$(basename "$REPO_DIR").gma"
	rm -f "../$GMA_FILE"
	echo "Successfully deleted $GMA_FILE"
fi

