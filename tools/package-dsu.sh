#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bash device/motorola/lyriq/tools/package-dsu.sh [--check] [product-out] [output.zip]

Build a DSU package for the current custom_lyriq product. The archive contains
only the six dynamic partitions that belong to the product and places them at
the ZIP root, as required by DynamicSystemInstallationService.

--check       Validate the input images without creating an archive.
product-out   Defaults to $ANDROID_PRODUCT_OUT, or out/target/product/lyriq.
output.zip    Defaults to <product-out>/pixelos_lyriq-dsu.zip.
EOF
}

mode=package
if [[ "${1:-}" == "--check" ]]; then
    mode=check
    shift
fi

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
fi

if (( $# > 2 )); then
    usage >&2
    exit 2
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
android_root="$(cd -- "$script_dir/../../../.." && pwd)"
default_product_out="$android_root/out/target/product/lyriq"
product_out="${1:-${ANDROID_PRODUCT_OUT:-$default_product_out}}"
output_path="${2:-$product_out/pixelos_lyriq-dsu.zip}"

readonly -a images=(
    system.img
    system_ext.img
    product.img
    vendor.img
    system_dlkm.img
    vendor_dlkm.img
)

if [[ ! -d "$product_out" ]]; then
    printf 'Missing product output directory: %s\n' "$product_out" >&2
    exit 1
fi

for image in "${images[@]}"; do
    image_path="$product_out/$image"
    if [[ ! -s "$image_path" ]]; then
        printf 'Missing or empty image: %s\n' "$image_path" >&2
        exit 1
    fi
    printf '%s %s bytes\n' "$image" "$(stat --format='%s' "$image_path")"
done

if [[ "$mode" == check ]]; then
    printf 'All lyriq DSU input images are present.\n'
    exit 0
fi

for command in zip unzip sha256sum; do
    if ! command -v "$command" >/dev/null; then
        printf 'Required command is unavailable: %s\n' "$command" >&2
        exit 1
    fi
done

output_path="$(realpath -m -- "$output_path")"
if [[ -e "$output_path" ]]; then
    printf 'Refusing to overwrite existing archive: %s\n' "$output_path" >&2
    exit 1
fi

mkdir -p -- "$(dirname -- "$output_path")"
(
    cd -- "$product_out"
    zip -0 -X "$output_path" "${images[@]}"
)
zip -T "$output_path"

expected_entries="$(printf '%s\n' "${images[@]}")"
actual_entries="$(unzip -Z1 "$output_path")"
if [[ "$actual_entries" != "$expected_entries" ]]; then
    printf 'Invalid DSU archive entries in %s\n' "$output_path" >&2
    printf 'Expected:\n%s\nActual:\n%s\n' "$expected_entries" "$actual_entries" >&2
    exit 1
fi

printf 'Created DSU package: %s\n' "$output_path"
sha256sum "$output_path"