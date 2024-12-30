#!/bin/bash

# Set repository information
REPO="repasscloud/CSLama"
BASE_URL="https://github.com/$REPO/releases/latest"

# Fetch the HTML of the latest release page
echo "Fetching latest release page..."
HTML=$(curl -Ls "$BASE_URL")
if [[ $? -ne 0 || -z "$HTML" ]]; then
    echo "Error: Unable to fetch the latest release page."
    exit 1
fi

# Save the HTML to a debug file for inspection
DEBUG_FILE="debug_latest_release.html"
echo "$HTML" > "$DEBUG_FILE"

# Extract the version number from the <title> tag
VERSION=$(echo "$HTML" | grep -oE '<title>Release v[0-9]{4}-[0-9]{2}-[0-9]{2} ·' | grep -oE 'v[0-9]{4}-[0-9]{2}-[0-9]{2}' | sed 's/v//')
if [[ -z "$VERSION" ]]; then
    echo "Error: Unable to extract the version number from the release page."
    exit 1
fi
echo "Latest release version: $VERSION"

# Construct the ZIP file URL
ZIP_URL="https://github.com/$REPO/releases/download/$VERSION/master-files-$VERSION.zip"
echo "Using ZIP file URL: $ZIP_URL"

# Download the ZIP file
curl -L -o "master-files-$VERSION.zip" "$ZIP_URL"
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to download ZIP file."
    exit 1
fi

# Unzip the file
UNZIP_DIR="unzipped"
mkdir -p "$UNZIP_DIR"
unzip "master-files-$VERSION.zip" -d "$UNZIP_DIR"
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to unzip file."
    exit 1
fi

# Process .txt files
PROCESSED_DIR="processed"
mkdir -p "$PROCESSED_DIR"

# Move all .txt files but exclude `combined.txt` if it exists
find "$UNZIP_DIR" -type f -name "*.txt" ! -name "combined.txt" -exec mv {} "$PROCESSED_DIR/" \;

COMBINED_FILE="$PROCESSED_DIR/combined.txt"
> "$COMBINED_FILE" # Create or clear the combined file

# Add all .txt files to the combined file, excluding the combined file itself
for TXT_FILE in "$PROCESSED_DIR"/*.txt; do
    if [[ "$TXT_FILE" != "$COMBINED_FILE" ]]; then
        echo "Adding $TXT_FILE to combined file..."
        cat "$TXT_FILE" >> "$COMBINED_FILE"
    fi
done

# Remove blank lines
sed -i '/^$/d' "$COMBINED_FILE"

# Output the combined file
echo "Contents of the combined file:"
ls -lh "$COMBINED_FILE" # Show size of the combined file
