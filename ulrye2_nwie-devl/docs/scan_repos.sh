#!/bin/bash

# Comprehensive GitHub Repository Scanner
# Scans all git repos in /c/devl and generates CSV

OUTPUT_FILE="/c/devl/github_repos_inventory.csv"
TEMP_FILE="/tmp/repos_data.txt"

# Header for CSV
echo "GH_Repo_Name,Remote_URL,Branch_Checked_Out,Latest_Commit_SHA,Date_Most_Recent_Change,Absolute_Path,Other_Available_Branches,Unpushed_Commits,Uncommitted_Changes,Untracked_Files,Stashed_Changes,Local_Only_Branches,Last_Commit_Date,Number_of_Commits,Last_Push_Date,Is_Fork,Is_Nested_Repo,Duplicate_Indicator" > "$OUTPUT_FILE"

# Find all .git directories and process
TOTAL_REPOS=$(find /c/devl -name ".git" -type d 2>/dev/null | wc -l)
COUNTER=0

echo "Found $TOTAL_REPOS git repositories. Starting scan..."

# Collect all repo paths first
find /c/devl -name ".git" -type d 2>/dev/null | while IFS= read -r git_dir; do
    COUNTER=$((COUNTER + 1))
    REPO_ROOT=$(dirname "$git_dir")
    PERCENT=$((COUNTER * 100 / TOTAL_REPOS))
    
    echo "[${PERCENT}%] Processing $COUNTER/$TOTAL_REPOS: $REPO_ROOT"
    
    cd "$REPO_ROOT" || continue
    
    # Get remote URL
    REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null)
    if [ -z "$REMOTE_URL" ]; then
        continue
    fi
    
    # Extract repo name
    REPO_NAME=$(basename "$REMOTE_URL" .git)
    
    # Get current branch
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    
    # Get latest commit SHA (short)
    COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null)
    
    # Get date of most recent change
    LAST_CHANGE=$(git log -1 --format=%aI 2>/dev/null)
    
    # Get all other branches (local)
    OTHER_BRANCHES=$(git branch 2>/dev/null | grep -v "^\\*" | tr '\n' ';' | sed 's/;$//')
    [ -z "$OTHER_BRANCHES" ] && OTHER_BRANCHES="N/A"
    
    # Check for uncommitted changes
    UNCOMMITTED=$([ -z "$(git status --porcelain 2>/dev/null)" ] && echo "NO" || echo "YES")
    
    # Check for untracked files
    UNTRACKED=$([ -z "$(git ls-files --others --exclude-standard 2>/dev/null)" ] && echo "NO" || echo "YES")
    
    # Check for stashed changes
    STASHED=$([ -z "$(git stash list 2>/dev/null)" ] && echo "NO" || echo "YES")
    
    # Count unpushed commits
    UNPUSHED=$(git log "origin/$BRANCH..HEAD" 2>/dev/null | wc -l)
    if [ "$UNPUSHED" -eq 0 ]; then
        UNPUSHED=$(git log --all --not --remotes 2>/dev/null | wc -l)
    fi
    
    # Get commit count
    COMMIT_COUNT=$(git log --oneline 2>/dev/null | wc -l)
    
    # Get last commit date
    LAST_COMMIT=$(git log -1 --format=%aI 2>/dev/null)
    
    # Get last push date (heuristic)
    LAST_PUSH=$(git log -1 --format=%aI 2>/dev/null)
    
    # Check if fork
    IS_FORK=$([ -n "$(git config --get remote.upstream.url 2>/dev/null)" ] && echo "YES" || echo "NO")
    
    # Check if nested repo
    IS_NESTED="NO"
    PARENT_DIR=$(dirname "$REPO_ROOT")
    while [ -n "$PARENT_DIR" ] && [ "$PARENT_DIR" != "/c/devl" ]; do
        if [ -d "$PARENT_DIR/.git" ]; then
            IS_NESTED="YES"
            break
        fi
        PARENT_DIR=$(dirname "$PARENT_DIR")
    done
    
    # Escape commas and quotes in data
    REMOTE_URL_ESCAPED="${REMOTE_URL//\"/\\\"}"
    REPO_PATH_ESCAPED="${REPO_ROOT//\"/\\\"}"
    
    # Output CSV row
    echo "\"$REPO_NAME\",\"$REMOTE_URL_ESCAPED\",\"$BRANCH\",\"$COMMIT_SHA\",\"$LAST_CHANGE\",\"$REPO_PATH_ESCAPED\",\"$OTHER_BRANCHES\",\"$UNPUSHED\",\"$UNCOMMITTED\",\"$UNTRACKED\",\"$STASHED\",\"$OTHER_BRANCHES\",\"$LAST_COMMIT\",\"$COMMIT_COUNT\",\"$LAST_PUSH\",\"$IS_FORK\",\"$IS_NESTED\",\"PENDING\"" >> "$OUTPUT_FILE"
    
done

# Count duplicates in a second pass
echo "Finalizing duplicate detection..."

# Create a new CSV with duplicate indicators
TEMP_CSV=$(mktemp)
head -1 "$OUTPUT_FILE" > "$TEMP_CSV"

# Get list of all repos and their counts
awk -F',' 'NR>1 {print $1}' "$OUTPUT_FILE" | sort | uniq -c | while read count repo_name; do
    if [ "$count" -gt 1 ]; then
        grep "^\"$repo_name\"," "$OUTPUT_FILE" | sed "s/,\"PENDING\"/,\"YES - $count instances\"/" >> "$TEMP_CSV"
    else
        grep "^\"$repo_name\"," "$OUTPUT_FILE" | sed 's/,\"PENDING\"/,\"NO"/' >> "$TEMP_CSV"
    fi
done

# Replace original with processed version
mv "$TEMP_CSV" "$OUTPUT_FILE"

# Print summary
echo ""
echo "========================================="
echo "* Export Complete *"
echo "Output file: $OUTPUT_FILE"
echo "Total repositories: $(tail -n +2 "$OUTPUT_FILE" | wc -l)"
echo ""
echo "Summary Statistics:"
echo "Uncommitted changes: $(grep ',YES,' "$OUTPUT_FILE" | grep -c ',YES,')"
echo "Untracked files: $(awk -F',' '$10=="\"YES\"" "$OUTPUT_FILE" | wc -l)"
echo "Unpushed commits: $(awk -F',' '$8>0' "$OUTPUT_FILE" | wc -l)"
echo "Nested repos: $(grep 'YES","YES' "$OUTPUT_FILE" | wc -l)"
echo "Forks: $(awk -F',' '$16=="\"YES\"" "$OUTPUT_FILE" | wc -l)"
echo "========================================="
