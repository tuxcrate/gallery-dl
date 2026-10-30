#!/usr/bin/env bash
set -euo pipefail

image=${1:?A locally loaded image is required}
version=${2:?The expected application version is required}
platform=${3:?The image platform is required}
container=
phase='running the default help command'
cleanup() {
    status=$?
    if [[ -n $container ]]; then
        if ((status != 0)); then
            printf 'gallery-dl smoke test failed while %s (exit status %s).\n' "$phase" "$status" >&2
            docker inspect --format '{{json .State}}' "$container" >&2 || true
            docker logs "$container" >&2 || true
        fi
        docker rm --force --volumes "$container" > /dev/null || true
    fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

run_cli() {
    container=$(docker create --pull=never --platform "$platform" --network none \
        --label "io.tuxcrate.smoke-test=${TUXCRATE_TEST_ID:-manual-gallery-dl-$$}" "$image" "$@")
    docker start "$container" > /dev/null
    exit_code=$(timeout 30 docker wait "$container")
    if [[ $exit_code != 0 ]]; then
        printf 'gallery-dl returned exit status %s.\n' "$exit_code" >&2
        exit 1
    fi
}

run_cli
docker rm --volumes "$container" > /dev/null
container=

phase='checking the installed version through the production entrypoint'
run_cli --version
installed_version=$(docker logs "$container")
if [[ $installed_version != "$version" ]]; then
    printf 'Expected gallery-dl %s, got %s.\n' "$version" "$installed_version" >&2
    exit 1
fi
