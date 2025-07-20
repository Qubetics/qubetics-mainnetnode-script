#!/bin/bash
# shellcheck disable=SC2016
set -e

# Detect OS and Architecture
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    "Linux")
        case "$ARCH" in
            "x86_64") ARCH="amd64" ;;
            "aarch64") ARCH="arm64" ;;
            "armv6" | "armv7l") ARCH="armv6l" ;;
            "armv8") ARCH="arm64" ;;
            *386*) ARCH="386" ;;
        esac
        PLATFORM="linux-$ARCH"
        ;;
    "Darwin")
        case "$ARCH" in
            "x86_64") ARCH="amd64" ;;
            "arm64") ARCH="arm64" ;;
        esac
        PLATFORM="darwin-$ARCH"
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

# Set default paths
[ -z "$GOROOT" ] && GOROOT="$HOME/.go"
[ -z "$GOPATH" ] && GOPATH="$HOME/go"

# Automatically fetch the latest Go version for this platform
# VERSION=$(curl -s https://go.dev/dl/ | grep "$PLATFORM.tar.gz" | sed -E "s/.*go([0-9.]+)\.$PLATFORM\.tar\.gz.*/\1/" | head -n 1)

VERSION=1.23.11

# Handle CLI options
print_help() {
    echo "Usage: bash goinstall.sh [OPTIONS]"
    echo -e "\nOPTIONS:"
    echo -e "  --remove         Remove currently installed Go"
    echo -e "  --version X.Y.Z  Specify a Go version to install"
    echo -e "  --help           Show this help message"
}

if [ "$1" == "--remove" ]; then
    echo "Removing Go from $GOROOT ..."
    rm -rf "$GOROOT"
    shell_profile=""
    if [ -n "$($SHELL -c 'echo $ZSH_VERSION')" ]; then
        shell_profile="$HOME/.zshrc"
    elif [ -n "$($SHELL -c 'echo $BASH_VERSION')" ]; then
        shell_profile="$HOME/.bashrc"
    elif [ -n "$($SHELL -c 'echo $FISH_VERSION')" ]; then
        shell="fish"
        if [ -d "$XDG_CONFIG_HOME" ]; then
            shell_profile="$XDG_CONFIG_HOME/fish/config.fish"
        else
            shell_profile="$HOME/.config/fish/config.fish"
        fi
    fi

    if [ -f "$shell_profile" ]; then
        if [ "$shell" == "fish" ]; then
            sed -i '' '/# GoLang/d;/set GOROOT/d;/set GOPATH/d;/set PATH.*GOROOT.*GOPATH/d' "$shell_profile"
        else
            sed -i '' '/# GoLang/d;/export GOROOT/d;/export GOPATH/d;/GOROOT\/bin/d;/GOPATH\/bin/d' "$shell_profile"
        fi
    fi
    echo "✅ Go removed."
    exit 0
elif [ "$1" == "--help" ]; then
    print_help
    exit 0
elif [ "$1" == "--version" ]; then
    if [ -z "$2" ]; then
        echo "❌ Please provide a version number with --version (e.g., --version 1.22.3)"
        exit 1
    else
        VERSION=$2
    fi
elif [ -n "$1" ]; then
    echo "❌ Unrecognized option: $1"
    exit 1
fi

# Check if already installed
if [ -d "$GOROOT" ]; then
    read -p "⚠️  Go is already installed at $GOROOT. Overwrite? (y/n): " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }
    rm -rf "$GOROOT"
fi

PACKAGE_NAME="go$VERSION.$PLATFORM.tar.gz"
TEMP_DIRECTORY=$(mktemp -d)

echo "⬇️  Downloading $PACKAGE_NAME ..."
if command -v wget >/dev/null 2>&1; then
    wget -q "https://go.dev/dl/$PACKAGE_NAME" -O "$TEMP_DIRECTORY/go.tar.gz"
else
    curl -sL "https://go.dev/dl/$PACKAGE_NAME" -o "$TEMP_DIRECTORY/go.tar.gz"
fi

# Validate the download
if ! file "$TEMP_DIRECTORY/go.tar.gz" | grep -q 'gzip compressed'; then
    echo "❌ Downloaded file is not a valid tar.gz archive. Likely a 404 error."
    cat "$TEMP_DIRECTORY/go.tar.gz" | head -n 10
    exit 1
fi

echo "📦 Extracting Go archive..."
mkdir -p "$GOROOT"
tar -C "$GOROOT" --strip-components=1 -xzf "$TEMP_DIRECTORY/go.tar.gz"

# Determine shell profile
shell_profile=""
if [ -n "$($SHELL -c 'echo $ZSH_VERSION')" ]; then
    shell_profile="$HOME/.zshrc"
elif [ -n "$($SHELL -c 'echo $BASH_VERSION')" ]; then
    shell_profile="$HOME/.bashrc"
elif [ -n "$($SHELL -c 'echo $FISH_VERSION')" ]; then
    shell="fish"
    if [ -d "$XDG_CONFIG_HOME" ]; then
        shell_profile="$XDG_CONFIG_HOME/fish/config.fish"
    else
        shell_profile="$HOME/.config/fish/config.fish"
    fi
fi

echo "⚙️  Configuring shell profile: $shell_profile"
touch "$shell_profile"
if [ "$shell" == "fish" ]; then
    {
        echo '# GoLang'
        echo "set -x GOROOT '$GOROOT'"
        echo "set -x GOPATH '$GOPATH'"
        echo 'set -x PATH $GOPATH/bin $GOROOT/bin $PATH'
    } >> "$shell_profile"
else
    {
        echo '# GoLang'
        echo "export GOROOT=$GOROOT"
        echo "export GOPATH=$GOPATH"
        echo 'export PATH=$GOPATH/bin:$GOROOT/bin:$PATH'
    } >> "$shell_profile"
fi

mkdir -p "$GOPATH"/{src,pkg,bin}

echo -e "\n✅ Go $VERSION installed at $GOROOT"
echo "💡 Please run: source $shell_profile"
echo "   or restart your terminal to apply environment changes."

rm -rf "$TEMP_DIRECTORY"
