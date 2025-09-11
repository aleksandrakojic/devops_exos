#!/bin/bash

# Define the hash store file
HASH_FILE="file_hashes.txt"

# Function to compute sha256 hash
compute_hash() {
    sha256sum "$1" | awk '{print $1}'
}

# Function to initialize hashes
init_hashes() {
    > "$HASH_FILE"
    find "$1" -type f | while read -r file; do
        hash=$(compute_hash "$file")
        echo "$file $hash" >> "$HASH_FILE"
        echo "Hashed $file"
    done
    echo "Hashes stored successfully."
}

# Function to check hashes
check_hashes() {
    if [ ! -f "$HASH_FILE" ]; then
        echo "Hash file not found. Please run init first."
        exit 1
    fi

    while read -r line; do
        file=$(echo "$line" | awk '{print $1}')
        stored_hash=$(echo "$line" | awk '{print $2}')

        if [ ! -f "$file" ]; then
            echo "$file: File missing!"
            continue
        fi

        current_hash=$(compute_hash "$file")
        if [ "$current_hash" != "$stored_hash" ]; then
            echo "$file: Status: Modified (Hash mismatch)"
        else
            echo "$file: Status: Unmodified"
        fi
    done < "$HASH_FILE"
}

# Function to update hashes
update_hashes() {
    > "$HASH_FILE"
    find "$1" -type f | while read -r file; do
        hash=$(compute_hash "$file")
        echo "$file $hash" >> "$HASH_FILE"
        echo "Hash for $file updated."
    done
    echo "Hash update completed."
}

# Main script logic
case "$1" in
    init)
        if [ -z "$2" ]; then
            echo "Usage: $0 init <directory_or_file>"
            exit 1
        fi
        init_hashes "$2"
        ;;
    check)
        if [ -z "$2" ]; then
            echo "Usage: $0 check <directory_or_file>"
            exit 1
        fi
        check_hashes "$2"
        ;;
    update)
        if [ -z "$2" ]; then
            echo "Usage: $0 update <directory_or_file>"
            exit 1
        fi
        update_hashes "$2"
        ;;
    *)
        echo "Usage: $0 {init|check|update} <path>"
        exit 1
        ;;
esac