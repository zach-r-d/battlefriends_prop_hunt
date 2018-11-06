#!/bin/bash
set -euo pipefail

function usage() {
	cat <<EOF
Addon packaging script; currently very rudimentary

-h, --help      - Print help and exit
-t, --test      - Test packaging only (delete package if successfully built)

EOF
	exit 1
}

ISTEST=""

while [[ $# -gt 0 ]]; do
key="$1"

case $key in
	-h|--help)
		usage
	;;
	-t|--test)
		ISTEST=true
		shift # past argument
	;;
	*)	# unknown option
		echo "Unknown option: '$1'"
		usage
	;;
esac
done

REPO_DIR=$(dirname "$(realpath $0)")

# operate in the directory ABOVE the addon
cd "$REPO_DIR/.."

winpty ../../bin/gmad.exe create -folder "$REPO_DIR"

if [[ $ISTEST ]]; then
	GMA_FILE="$(basename "$REPO_DIR").gma"
	rm -f "./$GMA_FILE"
	echo "Successfully deleted $GMA_FILE (as this was just a test)"
fi

