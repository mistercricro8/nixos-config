#!/usr/bin/env bash
set -eo pipefail

show_help() {
    cat << 'EOF'
Usage: catppuccin-to-dms [options] [input_file]

Converts a Catppuccin-themed configuration or palette file into a generic DankMaterialShell (DMS) template.

Input Priority:
  1. Input file argument [input_file]
  2. Standard input (stdin) if piped
  3. System clipboard (wl-paste or xclip)

Options:
  -o, --output <file>    Write converted template to specified file instead of stdout
  -y, --yellow <token>   Custom token placeholder for Catppuccin Yellow (default: %tertiary%)
  -h, --help             Show this help message

Examples:
  catppuccin-to-dms Catppuccin-Mocha.tmTheme -o dms.template.tmTheme
  wl-paste | catppuccin-to-dms > dms.template.conf
  echo "#f9e2af #1e1e2e #9399b240" | catppuccin-to-dms
EOF
}

output_file=""
yellow_token="%tertiary%"
input_file=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -o|--output)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "[ERROR] Missing value for --output" >&2
                exit 1
            fi
            output_file="$2"
            shift 2
            ;;
        --output=*)
            output_file="${1#*=}"
            shift
            ;;
        -y|--yellow)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "[ERROR] Missing value for --yellow" >&2
                exit 1
            fi
            yellow_token="$2"
            shift 2
            ;;
        --yellow=*)
            yellow_token="${1#*=}"
            shift
            ;;
        -*)
            echo "[ERROR] Unknown option: $1" >&2
            show_help
            exit 1
            ;;
        *)
            if [[ -z "$input_file" ]]; then
                input_file="$1"
            else
                echo "[ERROR] Unexpected argument: $1" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

# Read content into variable
input_content=""
if [[ -n "$input_file" ]]; then
    if [[ ! -f "$input_file" ]]; then
        echo "[ERROR] File not found: $input_file" >&2
        exit 1
    fi
    input_content="$(cat "$input_file")"
elif [[ ! -t 0 ]]; then
    input_content="$(cat)"
elif command -v wl-paste &>/dev/null; then
    input_content="$(wl-paste 2>/dev/null || true)"
elif command -v xclip &>/dev/null; then
    input_content="$(xclip -selection clipboard -o 2>/dev/null || true)"
fi

if [[ -z "$input_content" ]]; then
    echo "[ERROR] No input content found from file argument, stdin, or clipboard." >&2
    show_help
    exit 1
fi

# Define substitution logic in Perl for clean case-insensitive 6-digit & 8-digit hex replacements preserving alpha channels
result="$(echo "$input_content" | perl -pe '
    # Custom yellow token parameter
    my $yt = "'"$yellow_token"'";

    # Catppuccin Mocha
    s/#1e1e2e([0-9a-fA-F]{2})?/\%background\%$1/gi;
    s/#181825([0-9a-fA-F]{2})?/\%surface_dim\%$1/gi;
    s/#11111b([0-9a-fA-F]{2})?/\%surface_container_lowest\%$1/gi;
    s/#313244([0-9a-fA-F]{2})?/\%surface_container\%$1/gi;
    s/#45475a([0-9a-fA-F]{2})?/\%surface_container_high\%$1/gi;
    s/#585b70([0-9a-fA-F]{2})?/\%surface_container_highest\%$1/gi;
    s/#3e5767([0-9a-fA-F]{2})?/\%surface_variant\%$1/gi;
    s/#6c7086([0-9a-fA-F]{2})?/\%outline_variant\%$1/gi;
    s/#7f849c([0-9a-fA-F]{2})?/\%outline\%$1/gi;
    s/#9399b2([0-9a-fA-F]{2})?/\%on_surface_variant\%$1/gi;
    s/#a6adc8([0-9a-fA-F]{2})?/\%on_surface_variant\%$1/gi;
    s/#bac2de([0-9a-fA-F]{2})?/\%on_surface\%$1/gi;
    s/#cdd6f4([0-9a-fA-F]{2})?/\%on_surface\%$1/gi;

    s/#f38ba8([0-9a-fA-F]{2})?/\%secondary_fixed\%$1/gi;
    s/#eba0ac([0-9a-fA-F]{2})?/\%secondary\%$1/gi;
    s/#fab387([0-9a-fA-F]{2})?/\%secondary\%$1/gi;
    s/#f9e2af([0-9a-fA-F]{2})?/${yt}$1/gi;
    s/#a6e3a1([0-9a-fA-F]{2})?/\%tertiary\%$1/gi;
    s/#94e2d5([0-9a-fA-F]{2})?/\%secondary_container\%$1/gi;
    s/#89dceb([0-9a-fA-F]{2})?/\%tertiary_container\%$1/gi;
    s/#74c7ec([0-9a-fA-F]{2})?/\%primary_fixed\%$1/gi;
    s/#89b4fa([0-9a-fA-F]{2})?/\%primary\%$1/gi;
    s/#b4befe([0-9a-fA-F]{2})?/\%primary_container\%$1/gi;
    s/#cba6f7([0-9a-fA-F]{2})?/\%primary\%$1/gi;
    s/#f5c2e7([0-9a-fA-F]{2})?/\%secondary_fixed\%$1/gi;
    s/#f2cdcd([0-9a-fA-F]{2})?/\%secondary_fixed_dim\%$1/gi;
    s/#f5e0dc([0-9a-fA-F]{2})?/\%on_primary_fixed\%$1/gi;

    # Catppuccin Macchiato
    s/#24273a([0-9a-fA-F]{2})?/\%background\%$1/gi;
    s/#1e2030([0-9a-fA-F]{2})?/\%surface_dim\%$1/gi;
    s/#181926([0-9a-fA-F]{2})?/\%surface_container_lowest\%$1/gi;
    s/#363a4f([0-9a-fA-F]{2})?/\%surface_container\%$1/gi;
    s/#494d64([0-9a-fA-F]{2})?/\%surface_container_high\%$1/gi;
    s/#5b6078([0-9a-fA-F]{2})?/\%surface_container_highest\%$1/gi;
    s/#6e738d([0-9a-fA-F]{2})?/\%outline_variant\%$1/gi;
    s/#8087a2([0-9a-fA-F]{2})?/\%outline\%$1/gi;
    s/#939ab7([0-9a-fA-F]{2})?/\%on_surface_variant\%$1/gi;
    s/#a5adcb([0-9a-fA-F]{2})?/\%on_surface_variant\%$1/gi;
    s/#b8c0e0([0-9a-fA-F]{2})?/\%on_surface\%$1/gi;
    s/#cad3f5([0-9a-fA-F]{2})?/\%on_surface\%$1/gi;
    s/#ed8796([0-9a-fA-F]{2})?/\%secondary_fixed\%$1/gi;
    s/#ee99a0([0-9a-fA-F]{2})?/\%secondary\%$1/gi;
    s/#f5a97f([0-9a-fA-F]{2})?/\%secondary\%$1/gi;
    s/#eed49f([0-9a-fA-F]{2})?/${yt}$1/gi;
    s/#a6da95([0-9a-fA-F]{2})?/\%tertiary\%$1/gi;
    s/#8bd5ca([0-9a-fA-F]{2})?/\%secondary_container\%$1/gi;
    s/#91d7e3([0-9a-fA-F]{2})?/\%tertiary_container\%$1/gi;
    s/#7dc4e4([0-9a-fA-F]{2})?/\%primary_fixed\%$1/gi;
    s/#8aadf4([0-9a-fA-F]{2})?/\%primary\%$1/gi;
    s/#b7bdf8([0-9a-fA-F]{2})?/\%primary_container\%$1/gi;
    s/#c6a0f6([0-9a-fA-F]{2})?/\%primary\%$1/gi;
    s/#f5bde6([0-9a-fA-F]{2})?/\%secondary_fixed\%$1/gi;

    # Catppuccin Frappe
    s/#302d41([0-9a-fA-F]{2})?/\%background\%$1/gi;
    s/#292537([0-9a-fA-F]{2})?/\%surface_dim\%$1/gi;
    s/#23202e([0-9a-fA-F]{2})?/\%surface_container_lowest\%$1/gi;
    s/#413e52([0-9a-fA-F]{2})?/\%surface_container\%$1/gi;
    s/#514d64([0-9a-fA-F]{2})?/\%surface_container_high\%$1/gi;
    s/#625e77([0-9a-fA-F]{2})?/\%surface_container_highest\%$1/gi;
    s/#736f8d([0-9a-fA-F]{2})?/\%outline_variant\%$1/gi;
    s/#837fc1([0-9a-fA-F]{2})?/\%outline\%$1/gi;
    s/#c6d0f5([0-9a-fA-F]{2})?/\%on_surface\%$1/gi;
    s/#e78284([0-9a-fA-F]{2})?/\%secondary_fixed\%$1/gi;
    s/#e5c890([0-9a-fA-F]{2})?/${yt}$1/gi;
    s/#a6d189([0-9a-fA-F]{2})?/\%tertiary\%$1/gi;
    s/#81c8be([0-9a-fA-F]{2})?/\%secondary_container\%$1/gi;
    s/#99d1db([0-9a-fA-F]{2})?/\%tertiary_container\%$1/gi;
    s/#85c1dc([0-9a-fA-F]{2})?/\%primary_fixed\%$1/gi;
    s/#8caaee([0-9a-fA-F]{2})?/\%primary\%$1/gi;
    s/#babbf1([0-9a-fA-F]{2})?/\%primary_container\%$1/gi;
    s/#ca9ee6([0-9a-fA-F]{2})?/\%primary\%$1/gi;

    # Catppuccin Latte
    s/#eff1f5([0-9a-fA-F]{2})?/\%background\%$1/gi;
    s/#e6e9ef([0-9a-fA-F]{2})?/\%surface_dim\%$1/gi;
    s/#dce0e8([0-9a-fA-F]{2})?/\%surface_container_lowest\%$1/gi;
    s/#ccd0da([0-9a-fA-F]{2})?/\%surface_container\%$1/gi;
    s/#bcc0cc([0-9a-fA-F]{2})?/\%surface_container_high\%$1/gi;
    s/#acb0be([0-9a-fA-F]{2})?/\%surface_container_highest\%$1/gi;
    s/#9ca0b0([0-9a-fA-F]{2})?/\%outline_variant\%$1/gi;
    s/#8c8fa1([0-9a-fA-F]{2})?/\%outline\%$1/gi;
    s/#7c7f93([0-9a-fA-F]{2})?/\%on_surface_variant\%$1/gi;
    s/#6c6f85([0-9a-fA-F]{2})?/\%on_surface_variant\%$1/gi;
    s/#5c5f77([0-9a-fA-F]{2})?/\%on_surface\%$1/gi;
    s/#4c4f69([0-9a-fA-F]{2})?/\%on_surface\%$1/gi;
    s/#d20f39([0-9a-fA-F]{2})?/\%secondary_fixed\%$1/gi;
    s/#e64553([0-9a-fA-F]{2})?/\%secondary\%$1/gi;
    s/#fe640b([0-9a-fA-F]{2})?/\%secondary\%$1/gi;
    s/#df8e1d([0-9a-fA-F]{2})?/${yt}$1/gi;
    s/#40a02b([0-9a-fA-F]{2})?/\%tertiary\%$1/gi;
    s/#179299([0-9a-fA-F]{2})?/\%secondary_container\%$1/gi;
    s/#04a5e5([0-9a-fA-F]{2})?/\%tertiary_container\%$1/gi;
    s/#209fb5([0-9a-fA-F]{2})?/\%primary_fixed\%$1/gi;
    s/#1e66f5([0-9a-fA-F]{2})?/\%primary\%$1/gi;
    s/#7287fd([0-9a-fA-F]{2})?/\%primary_container\%$1/gi;
    s/#8839ef([0-9a-fA-F]{2})?/\%primary\%$1/gi;
')"

if [[ -n "$output_file" ]]; then
    mkdir -p "$(dirname "$output_file")"
    echo "$result" > "$output_file"
    echo "[SUCCESS] Converted template written to $output_file"
else
    echo "$result"
fi
