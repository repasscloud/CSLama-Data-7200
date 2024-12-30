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

# Save the HTML to a debug file for inspection (optional, useful for troubleshooting)
DEBUG_FILE="debug_latest_release.html"
echo "$HTML" > "$DEBUG_FILE"
echo "Saved the release page HTML to $DEBUG_FILE for inspection."

# Extract the version number from the <h2> tag with class "sr-only" inside the relevant <div>
VERSION=$(echo "$HTML" | grep -oP '(?<=<h2 class="sr-only"[^>]*>v)\d{4}-\d{2}-\d{2}')
if [[ -z "$VERSION" ]]; then
    echo "Error: Unable to extract the version number from the release page."
    echo "Inspect the saved HTML file: $DEBUG_FILE"
    exit 1
fi
echo "Latest release version: $VERSION"

# Construct the ZIP file URL
ZIP_URL="https://github.com/$REPO/releases/download/$VERSION/master-files-$VERSION.zip"
echo "Using ZIP file URL: $ZIP_URL"

# Download the ZIP file
echo "Downloading ZIP file..."
curl -L -o "master-files-$VERSION.zip" "$ZIP_URL"
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to download ZIP file."
    exit 1
fi
echo "Downloaded ZIP file: master-files-$VERSION.zip"

# Unzip the file
UNZIP_DIR="unzipped"
mkdir -p "$UNZIP_DIR"
unzip "master-files-$VERSION.zip" -d "$UNZIP_DIR"
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to unzip file."
    exit 1
fi
echo "Unzipped files to: $UNZIP_DIR"

# Find and process .txt files
PROCESSED_DIR="processed"
mkdir -p "$PROCESSED_DIR"

echo "Processing .txt files..."
find "$UNZIP_DIR" -type f -name "*.txt" -exec mv {} "$PROCESSED_DIR/" \;

COMBINED_FILE="$PROCESSED_DIR/combined.txt"
> "$COMBINED_FILE" # Create or clear the combined file

for TXT_FILE in "$PROCESSED_DIR"/*.txt; do
    echo "Adding $TXT_FILE to combined file..."
    cat "$TXT_FILE" >> "$COMBINED_FILE"
done

# Remove blank lines
sed -i '/^$/d' "$COMBINED_FILE"
echo "Removed blank lines from combined file."

# Output the combined file
echo "Contents of the combined file:"
cat "$COMBINED_FILE"
