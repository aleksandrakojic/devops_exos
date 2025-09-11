import os
import sys
import hashlib
import json
import argparse

# Path to store hashes
HASH_STORE_FILE = 'file_hashes.json'

def compute_hash(file_path):
    """Compute SHA-256 hash of a file."""
    sha256 = hashlib.sha256()
    try:
        with open(file_path, 'rb') as f:
            for chunk in iter(lambda: f.read(8192), b''):
                sha256.update(chunk)
        return sha256.hexdigest()
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        return None

def load_hashes():
    """Load stored hashes from file."""
    if os.path.exists(HASH_STORE_FILE):
        with open(HASH_STORE_FILE, 'r') as f:
            return json.load(f)
    return {}

def save_hashes(hashes):
    """Save hashes to file."""
    with open(HASH_STORE_FILE, 'w') as f:
        json.dump(hashes, f, indent=4)

def get_files(target_path):
    """Get list of log files from directory or single file."""
    files = []
    if os.path.isfile(target_path):
        files.append(target_path)
    elif os.path.isdir(target_path):
        for root, dirs, filenames in os.walk(target_path):
            for filename in filenames:
                # Consider only log files if needed, or all files
                files.append(os.path.join(root, filename))
    else:
        print(f"Path not found: {target_path}")
    return files

def init_hashes(target_path):
    """Initialize and store hashes for files."""
    files = get_files(target_path)
    hashes = {}
    for file in files:
        h = compute_hash(file)
        if h:
            hashes[file] = h
            print(f"Hashed {file}")
    save_hashes(hashes)
    print("Hashes stored successfully.")

def check_files(target_path):
    """Check files against stored hashes."""
    stored_hashes = load_hashes()
    files = get_files(target_path)
    modified_files = []
    unmodified_files = []

    for file in files:
        current_hash = compute_hash(file)
        stored_hash = stored_hashes.get(file)
        if stored_hash is None:
            print(f"{file}: No stored hash (consider running init).")
            continue
        if current_hash != stored_hash:
            print(f"{file}: Status: Modified (Hash mismatch)")
            modified_files.append(file)
        else:
            print(f"{file}: Status: Unmodified")
            unmodified_files.append(file)

    if modified_files:
        print("\nModified files:")
        for f in modified_files:
            print(f" - {f}")

def update_hash(target_path):
    """Update stored hashes for files."""
    files = get_files(target_path)
    stored_hashes = load_hashes()
    for file in files:
        new_hash = compute_hash(file)
        if new_hash:
            stored_hashes[file] = new_hash
            print(f"Hash for {file} updated.")
    save_hashes(stored_hashes)
    print("Hash update completed.")

def main():
    parser = argparse.ArgumentParser(description='File Integrity Checker')
    parser.add_argument('command', choices=['init', 'check', 'update', '-check'], help='Operation to perform')
    parser.add_argument('path', help='File or directory path')
    args = parser.parse_args()

    if args.command == 'init':
        init_hashes(args.path)
    elif args.command == 'check':
        check_files(args.path)
    elif args.command == 'update':
        update_hash(args.path)
    elif args.command == '-check':
        check_files(args.path)
    else:
        print("Unknown command.")

if __name__ == "__main__":
    main()