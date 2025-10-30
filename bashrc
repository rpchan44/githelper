# ================================
#  Git Bash Helper Aliases & Functions
# ================================
# --- WORKFLOW ---
alias makepr='process'
alias preppr='gsquash'
alias cfrs='gconflict'
alias scf='show_conflict'
alias nuke='duke_nukem'
alias setreponame='reponame'
# --- Git Basics ---
alias gbn='gnew'
alias gbs='echo Branch Status; git status'
alias ga='echo Staging files; git add'
alias gau='echo Unstaging files; git reset HEAD'
alias gc='git commit -m'  # commit with branch prefix
alias gp='echo Pushing branch to remote; git push'

# --- Logs & Diff ---
alias gl='echo Gitlog with decorated output; git log --oneline --graph --decorate --all'
alias gll='echo Detailed log with colors; git log --color=always --graph --abbrev-commit --decorate --all'
alias gsh='echo Show latest commit details; git show HEAD'
alias gd='echo Diff unstaged changes; git diff'
alias gds='echo Diff staged changes; git diff --staged'

# --- Git Blame Aliases ---
alias gbbl='gblame'          # full file blame
alias gbln='gblame_line'    # blame specific line
alias gbls='gblame_show'    # show commit for line
alias gblh='gline_history'   # line history
alias gblr='gblame_recent'  # blame last N commits


# --- Branch Management ---
alias gclean="gclean-branch"
alias gbc="echo Cloning Repository; git clone "
alias gman='gbmanage'
alias gbsan='gbclean'
alias gpf='echo Push your local to remote (no matter what); pushforce'
alias gsf='echo Pull your remote branch to your local (no matter what); syncforce'

# --- Commit undo options
alias gundo='echo Undo last commit keep changes staged; git reset --soft HEAD~1'
alias gundoh='echo Undo last commit unstage changes, keep edits; git reset --mixed HEAD~1'
alias gundoall='echo Undo last commit and discard changes; git reset --hard HEAD~1'

# --- File Tracking ---
alias guntrack='echo Stop tracking file but keep locally; git rm --cached'
alias gcpy='gcpy'

# --- Stash Helpers ---
alias gstash='echo Saving changes to stash; git stash push -u'
alias gstashm='echo Saving changes to stash with message; git stash push -u -m'
alias gstashl='echo Listing stash entries; git stash list'
alias gstasha='echo Applying latest stash; git stash apply'
alias gstashp='echo Popping latest stash; git stash pop'
alias gstashd='echo Dropping stash by ID; git stash drop'
alias newrepo='repo_create'

# ================================
#  Directory Menu Helper
# ================================
cdmenu() {
    dirs=(*/)
    [ ${#dirs[@]} -eq 0 ] && { echo "No subdirectories found"; return 0; }
    echo "Select a directory:"
    select d in "${dirs[@]}"; do
        [ -n "$d" ] && cd "$d" && break
        echo "Invalid choice"
    done
}

# === Rename Git remote repo and optionally local folder ===
# === setreponame — rename remote repository both locally and on GitHub ===
reponame() {

  local remote="origin"
  local new_name=""

  # Parse arguments
  if [[ $# -eq 1 ]]; then
    new_name="$1"
  elif [[ $# -eq 2 ]]; then
    remote="$1"
    new_name="$2"
  else
    cat <<'USAGE'
Usage:
  setreponame [remote] <new-repo-name>

Examples:
  setreponame origin ghelper
  setreponame ghelper   # assumes 'origin' as remote
USAGE
    return 0
  fi

  # Ensure inside a git repo
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "❌ Not inside a git repository."
    return 0
  fi

  local old_url repo_full owner old_name
  old_url=$(git remote get-url "$remote" 2>/dev/null || true)
  if [[ -z "$old_url" ]]; then
    echo "❌ Remote '$remote' not found."
    return 0
  fi

  # --- Match GitHub-style URLs (HTTPS or SSH) ---
  if [[ "$old_url" =~ ^(https://|git@)github\.com[:/]+([^/]+)/([^/.]+)(\.git)?$ ]]; then
    owner="${BASH_REMATCH[2]}"
    old_name="${BASH_REMATCH[3]}"
    repo_full="${owner}/${old_name}"
  else
    echo "❌ Remote '$remote' does not point to a recognizable GitHub URL."
    echo "Current URL: $old_url"
    return 0
  fi

  echo "📦 Detected GitHub repo: $repo_full"
  echo "🆕 Renaming to: ${owner}/${new_name}"
  echo

  read -r -p "Proceed to rename GitHub repo '${old_name}' → '${new_name}'? [y/N] " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Cancelled."; return 0; }

  if ! gh auth status >/dev/null 2>&1; then
    echo "❌ GitHub CLI not authenticated. Run: gh auth login"
    return 0
  fi

  echo "🔧 Renaming remote repo on GitHub..."
  if ! gh repo rename "$new_name" --repo "$repo_full" >/dev/null; then
    echo "❌ GitHub rename failed. (Do you own this repo?)"
    return 0
  fi
  echo "✅ GitHub repository renamed successfully."

  local new_url="https://github.com/${owner}/${new_name}.git"
  echo "🔄 Updating local remote '$remote' URL → $new_url"
  git remote set-url "$remote" "$new_url"

  echo "📡 New remote list:"
  git remote -v

  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || true)
  if [[ -n "$branch" ]]; then
    echo
    read -r -p "Update upstream tracking for '$branch' to '$remote/$branch'? [y/N] " upconfirm
    if [[ "$upconfirm" =~ ^[Yy]$ ]]; then
      git branch --set-upstream-to="$remote/$branch" "$branch"
      echo "✅ Upstream updated."
    fi
  fi

  # --- Optional folder rename ---
  local current_dir new_dir
  current_dir=$(basename "$(pwd)")
  new_dir="${new_name}"

  if [[ "$current_dir" != "$new_dir" ]]; then
    echo
    read -r -p "Rename local folder '$current_dir' → '$new_dir'? [y/N] " dirconfirm
    if [[ "$dirconfirm" =~ ^[Yy]$ ]]; then
      local parent_dir
      parent_dir=$(dirname "$(pwd)")
      cd "$parent_dir"
      mv "$current_dir" "$new_dir"
      cd "$new_dir"
      echo "📁 Folder renamed to '$new_dir'."
    fi
  fi

  echo
  echo "🎉 Done. Repository renamed on GitHub and synced locally."
}


# Convenient alias
alias grename='rename_git_remote'

# ================================
#  Remote Repo Helpers
# ================================
setremote() {
    [ $# -ne 2 ] && { echo "Usage: setremote <remote_name> <url>"; return 0; }
    local remote_name=$1 url=$2
    if git remote get-url "$remote_name" &>/dev/null; then
        echo "Updating remote '$remote_name' to $url"
        git remote set-url "$remote_name" "$url"
    else
        echo "Adding new remote '$remote_name' -> $url"
        git remote add "$remote_name" "$url"
    fi
    git remote -v
}

pushup() {
    local remote_name=${1:-origin}
    local branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD)
    [ -z "$branch" ] && { echo "Not on a branch"; return 0; }
    echo "Pushing branch '$branch' to remote '$remote_name'"
    git push -u "$remote_name" "$branch"
}

show_conflict() {
    echo -e "\e[31m<<<<<<< HEAD\e[0m"    # Red: your current branch changes
    echo "Your changes"
    echo -e "\e[33m=======\e[0m"       # Yellow: separator between changes
    echo "Incoming branch changes"
    echo -e "\e[32m>>>>>>> feature-branch\e[0m"  # Green: changes from the branch being merged

    echo
    echo -e "\e[36m# How to deal with this conflict:\e[0m"
    echo -e "\e[36m# 1. Decide what the final content should be:\e[0m"
    echo -e "\e[36m#    - Keep your changes only\e[0m"
    echo -e "\e[36m#    - Keep incoming changes only\e[0m"
    echo -e "\e[36m#    - Combine both changes manually\e[0m"
    echo -e "\e[36m# 2. Remove the conflict markers (<<<<<<<, =======, >>>>>>>)\e[0m"
    echo -e "\e[36m# 3. Stage the resolved file:\e[0m git add <file>"
    echo -e "\e[36m# 4. Continue merge or rebase:\e[0m git commit  # for merge"
    echo -e "\e[36m#    or git rebase --continue  # for rebase\e[0m"

}


gconflict() {
    # Check if VSCode is installed
    if ! command -v code &>/dev/null; then
        echo -e "\e[33mVSCode not found. Please install it to use this helper.\e[0m"
        return 0
    fi

    # Get list of conflicted files
    local conflicts
    conflicts=$(git diff --name-only --diff-filter=U)

    if [ -z "$conflicts" ]; then
        echo -e "\e[32mNo merge conflicts detected.\e[0m"
        return 0
    fi

    echo -e "\e[36mOpening conflicted files in VSCode...\e[0m"

    # Open each conflicted file in merge editor
    for file in $conflicts; do
        code --wait -n --merge "$file"
    done

    echo -e "\e[32mAll conflicted files opened in VSCode.\e[0m"
    echo -e "\e[33mResolve conflicts, then run 'git add <file>' and 'git rebase --continue' or 'git commit'.\e[0m"
}

gsquash() {
    # Squash all commits in current branch into one commit

    local BRANCH
    BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [ -z "$BRANCH" ]; then
        echo -e "\e[33mNot on a branch.\e[0m"
        return 0
    fi

    # Detect upstream/base branch automatically
    local UPSTREAM
    UPSTREAM=$(git for-each-ref --format='%(upstream:short)' "refs/heads/$BRANCH")
    
    if [ -z "$UPSTREAM" ]; then
        # If no upstream set, try to detect merge-base with main
        UPSTREAM="origin/main"
    fi

    # Find merge base commit
    local BASE
    BASE=$(git merge-base "$BRANCH" "$UPSTREAM")
    if [ -z "$BASE" ]; then
        echo -e "\e[33mCannot detect base commit between $BRANCH and $UPSTREAM\e[0m"
        return 0
    fi

    # Detect unstaged/staged changes or untracked files
    if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
        echo -e "\e[33mDetected changes/untracked files. Running 'git add .'...\e[0m"
        git add .
    fi

    # Prompt for new commit message
    local NEW_MSG
    read -rp "Enter new commit message: " NEW_MSG
    if [ -z "$NEW_MSG" ]; then
        echo -e "\e[33mCommit message cannot be empty.\e[0m"
        return 0
    fi

    echo -e "\e[36mSquashing all commits in branch '$BRANCH' into one since base '$UPSTREAM'...\e[0m"

    # Reset to the merge base (keep changes staged)
    git reset --soft "$BASE"

    # Commit as single commit
    git commit -m "$NEW_MSG"

    # Force push
    git push --force-with-lease

    # Red success message
    echo -e "\e[31mBranch '$BRANCH' successfully squashed and pushed!\e[0m"
}

#
# Usage:
#   gclean-branch                # detect current branch, switch to main, ask before delete
#   gclean-branch --force        # same but force delete (even if unmerged, still asks)
#   gclean-branch --remote       # also delete from remote (with confirmation)
#   gclean-branch --force --remote  # force delete both locally and remotely (with confirmation)
#
# Description:
#   This helper checks your current Git branch.
#   If it’s not 'main' or 'master', it switches to the default branch
#   and asks before deleting the old one.
#   If --force is passed, it uses 'git branch -D' instead of '-d'.
#   If --remote is passed, it will also confirm before deleting the remote branch.
#
# Examples:
#   gclean-branch
#   gclean-branch --force
#   gclean-branch --remote
#
# Notes:
#   Works with ghelp documentation system.

gclean-branch() {
  set -euo pipefail

  local current_branch
  local delete_flag="-d"
  local delete_remote=false
  local default_branch

  # Help output for ghelp
  if [[ "${1:-}" == "help" || "${1:-}" == "-h" ]]; then
    declare -f gclean-branch | sed -n 's/^# //p'
    return 0
  fi

  # Detect current branch
  current_branch=$(git branch --show-current 2>/dev/null || true)
  if [[ -z "$current_branch" ]]; then
    echo "Not in a Git repository or no branch detected."
    return 0
  fi

  # Parse args
  for arg in "$@"; do
    case "$arg" in
      --force) delete_flag="-D" ;;
      --remote) delete_remote=true ;;
    esac
  done

  # Detect main or master
  if git show-ref --quiet refs/heads/main; then
    default_branch="main"
  elif git show-ref --quiet refs/heads/master; then
    default_branch="master"
  else
    echo "No 'main' or 'master' branch found."
    return 0
  fi

  # Already on main/master
  if [[ "$current_branch" == "$default_branch" ]]; then
    echo "Already on '$default_branch', nothing to delete."
    return 0
  fi

  echo "Current branch: $current_branch"
  echo "Switching to '$default_branch'..."
  git switch "$default_branch"
  echo "Perform pulling on '$default_branch'..."
  git pull
  echo
  read -rp "Delete local branch '$current_branch'? [y/N]: " confirm_local
  if [[ ! "$confirm_local" =~ ^[Yy]$ ]]; then
    echo "Local branch deletion cancelled."
    return 0
  fi

  echo "Deleting local branch '$current_branch'..."
  git branch $delete_flag "$current_branch"

  # Remote delete (optional)
  if [[ "$delete_remote" == true ]]; then
    echo
    if git ls-remote --exit-code origin "refs/heads/$current_branch" &>/dev/null; then
      read -rp "Delete remote branch 'origin/$current_branch'? [y/N]: " confirm_remote
      if [[ "$confirm_remote" =~ ^[Yy]$ ]]; then
        echo "Deleting remote branch..."
        git push origin --delete "$current_branch"
        echo "Remote branch 'origin/$current_branch' deleted."
      else
        echo "Remote branch deletion cancelled."
      fi
    else
      echo "No remote branch found for '$current_branch'."
    fi
  fi

  echo "Branch '$current_branch' cleaned up successfully."
  return 0
}

# ================================
#  Remove files covered by .gitignore after the fact
# ================================

gbclean() {
    echo "Scanning for ignored but tracked files..."
    local ignored
    ignored=$(git ls-files -ci --exclude-standard)

    if [ -z "$ignored" ]; then
        echo "Nothing to clean"
        return 0
    fi

    echo "Removing and committing ignored files..."
    git rm --cached $ignored
    git commit -m "Remove ignored files now covered by .gitignore"
    echo "Done."
}

# ========================================
# Copy files within current Git branch
# Usage: gcopy <source> <destination>
# ========================================
gcpy() {
    if ! git rev-parse --show-toplevel &>/dev/null; then
        echo "Not inside a Git repository"
        return 0
    fi

    local repo_root
    repo_root=$(git rev-parse --show-toplevel)
    repo_root=$(cygpath -u "$repo_root")   # normalize → /c/Users/...

    if [[ $# -lt 2 ]]; then
        echo "Usage: gcpy <source...> <destination>"
        return 0
    fi

    local dest="${@: -1}"
    local sources=("${@:1:$#-1}")

    for src in "${sources[@]}"; do
        for f in $src; do
            local abs_src
            abs_src=$(realpath -m "$f" 2>/dev/null)
            abs_src=$(cygpath -u "$abs_src")

            shopt -s nocasematch
            if [[ "$abs_src" != "$repo_root"/* ]]; then
                echo "Blocked: '$f' is outside repo root"
                shopt -u nocasematch
                return 0
            fi
            shopt -u nocasematch
        done
    done

    local abs_dest
    abs_dest=$(realpath -m "$dest" 2>/dev/null)
    abs_dest=$(cygpath -u "$abs_dest")

    shopt -s nocasematch
    if [[ "$abs_dest" != "$repo_root"/* ]]; then
        echo "Blocked: destination '$dest' is outside repo root"
        shopt -u nocasematch
        return 0
    fi
    shopt -u nocasematch

    # Auto-create destination folder
    mkdir -p "$dest"

    cp -r "${sources[@]}" "$dest" && \
        echo "Copied ${sources[*]} → $dest"
}


# ================================
#  Git Blame & History Helpers
# ================================
gblame() {
    local file=$1
    [ -z "$file" ] && { echo "Usage: gblame <file>"; return 0; }
    git blame "$file"
}

gblame_line() {
    local file=$1 line=$2
    [ -z "$file" ] || [ -z "$line" ] && { echo "Usage: gblame_line <file> <line>"; return 0; }
    git blame -L "$line","$line" "$file"
}

gblame_show() {
    local file=$1 line=$2
    [ -z "$file" ] || [ -z "$line" ] && { echo "Usage: gblame_show <file> <line>"; return 0; }
    local commit=$(git blame -L "$line","$line" --porcelain "$file" | awk '/^commit/ {print $2}')
    echo " Commit for $file line $line: $commit"
    git show "$commit"
}

gline_history() {
    local file=$1 line=$2
    [ -z "$file" ] || [ -z "$line" ] && { echo "Usage: gline_history <file> <line>"; return 0; }
    git log -L "$line","$line":"$file"
}

gblame_recent() {
    local file=$1 count=${2:-5}
    [ -z "$file" ] && { echo "Usage: gblame_recent <file> [N_commits]"; return 0; }
    local range="HEAD~$count..HEAD"
    echo " Blaming $file for last $count commits ($range)"
    git blame "$range" -- "$file"
}


repo_create() {
    local repo_name visibility url

    repo_name=$1
    visibility=${2:-private}

    [ -z "$repo_name" ] && { echo "Usage: newrepo <repo_name> [private|public]"; return 0; }

    # Encode repo name for URL (basic encoding)
    repo_name_encoded=$(python -c "import urllib.parse; print(urllib.parse.quote('$repo_name'))")

    # GitHub new repo URL with pre-filled fields
    url="https://github.com/new?name=$repo_name_encoded&private=$( [[ "$visibility" == "private" ]] && echo true || echo false )"

    echo "Opening browser to create GitHub repo '$repo_name' ($visibility)"

    # Open URL in default browser on Windows
    if command -v start &>/dev/null; then
        start "" "$url"
    elif command -v xdg-open &>/dev/null; then
        xdg-open "$url"
    elif command -v open &>/dev/null; then
        open "$url"
    else
        echo "Please open this URL manually: $url"
    fi
}

remoteinfo() {
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD)
    [ -z "$branch" ] && { echo "Not on a branch"; return 0; }
    echo -e "\n Current branch: $branch"
    upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
    [ -n "$upstream" ] && echo "Tracking upstream: $upstream" || echo "No upstream set for this branch"
    echo -e "\n Remote repositories:"
    git remote -v
    echo
}

# ================================
#  Enhanced Git-Aware Prompt
# ================================
parse_git_status() {
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    [ -z "$branch" ] && return

    staged=$(git diff --cached --name-only 2>/dev/null | wc -l)
    unstaged=$(git diff --name-only 2>/dev/null | wc -l)
    untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l)
    dirty=""

    [ "${staged:-0}" -gt 0 ] && dirty+="+"
    [ "${unstaged:-0}" -gt 0 ] && dirty+="..."
    [ "${untracked:-0}" -gt 0 ] && dirty+="-"
    [ -z "$dirty" ] && dirty="OK"

    ahead=$(git rev-list --count --left-only @{u}...HEAD 2>/dev/null || echo 0)
    behind=$(git rev-list --count --right-only @{u}...HEAD 2>/dev/null || echo 0)
    ab=""

    [ "${ahead:-0}" -gt 0 ] && ab+="-->$ahead"
    [ "${behind:-0}" -gt 0 ] && ab+="<--$behind"

    echo " $branch $dirty $ab"
}

GREEN="\[\e[1;32m\]"
YELLOW="\[\e[1;33m\]"
BLUE="\[\e[1;34m\]"
RESET="\[\e[0m\]"

export PS1="$GREEN\u@\h $BLUE\w $YELLOW\$(parse_git_status)$RESET"
gbmanage() {
    local action=$1 target=$2 branch=$3 newname=$4
    local RED="\033[0;31m" GREEN="\033[0;32m" YELLOW="\033[1;33m" RESET="\033[0m"

    if [[ -z "$action" ]]; then
        echo -e "Usage:"
        echo -e "  gman list local"
        echo -e "  gman list remote"
        echo -e "  gman delete local <branch>"
        echo -e "  gman delete remote <branch>"
        echo -e "  gman rename local <old> <new>"
        echo -e "  gman rename remote <old> <new>"
        return 0
    fi

    # Validate repo
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo -e "${RED}Not inside a Git repository.${RESET}"
        return 0
    fi

    case "$action" in
        list)
            case "$target" in
                local)
                    echo -e "${GREEN} Local branches:${RESET}"
                    git branch --format="%(refname:short)" | sed "s/^/  - /"
                    ;;
                remote)
                    echo -e "${GREEN} Remote branches:${RESET}"
                    git for-each-ref --format="%(refname:short)" refs/remotes/ \
                        | sed "s/^/  - /"
                    ;;
                *)
                    echo -e "${RED}Invalid target. Use 'local' or 'remote'.${RESET}"
                    return 0
                    ;;
            esac
            ;;
        delete)
            if [[ "$target" == "local" ]]; then
                if ! git show-ref --verify --quiet "refs/heads/$branch"; then
                    echo -e "${RED}Local branch '$branch' does not exist.${RESET}"
                    return 0
                fi
                if [[ "$(git rev-parse --abbrev-ref HEAD)" == "$branch" ]]; then
                    echo -e "${RED}You cannot delete the branch you are currently on.${RESET}"
                    return 0
                fi
                echo -e "${YELLOW}Delete local branch '$branch'? (y/N)${RESET}"
                read -r ans
                [[ "$ans" =~ ^[Yy]$ ]] && git branch -D "$branch" \
                    && echo -e "${GREEN}Deleted local branch '$branch'.${RESET}"

            elif [[ "$target" == "remote" ]]; then
                local remote=$(git remote | head -n1)
                if [[ -z "$remote" ]]; then
                    echo -e "${RED}No remote configured.${RESET}"
                    return 0
                fi
                if ! git ls-remote --heads "$remote" "$branch" | grep -q .; then
                    echo -e "${RED}Remote branch '$branch' not found on '$remote'.${RESET}"
                    return 0
                fi
                echo -e "${YELLOW}Delete remote branch '$branch' from '$remote'? (y/N)${RESET}"
                read -r ans
                [[ "$ans" =~ ^[Yy]$ ]] && git push "$remote" --delete "$branch" \
                    && echo -e "${GREEN}Deleted remote branch '$branch' from '$remote'.${RESET}"
            else
                echo -e "${RED}Invalid target. Use 'local' or 'remote'.${RESET}"
                return 0
            fi
            ;;
        rename)
            if [[ -z "$newname" ]]; then
                echo -e "${RED}Missing new branch name.${RESET}"
                return 0
            fi
            if [[ "$target" == "local" ]]; then
                if ! git show-ref --verify --quiet "refs/heads/$branch"; then
                    echo -e "${RED}Local branch '$branch' does not exist.${RESET}"
                    return 0
                fi
                echo -e "${YELLOW}Rename local branch '$branch'  '$newname'? (y/N)${RESET}"
                read -r ans
                if [[ "$ans" =~ ^[Yy]$ ]]; then
                    git branch -m "$branch" "$newname"
                    echo -e "${GREEN}Renamed local branch '$branch'  '$newname'.${RESET}"
                fi
            elif [[ "$target" == "remote" ]]; then
                local remote=$(git remote | head -n1)
                if [[ -z "$remote" ]]; then
                    echo -e "${RED}No remote configured.${RESET}"
                    return 0
                fi
                if ! git ls-remote --heads "$remote" "$branch" | grep -q .; then
                    echo -e "${RED}Remote branch '$branch' not found on '$remote'.${RESET}"
                    return 0
                fi
                echo -e "${YELLOW}Rename remote branch '$branch'  '$newname' on '$remote'? (y/N)${RESET}"
                read -r ans
                if [[ "$ans" =~ ^[Yy]$ ]]; then
                    git push "$remote" "$branch:$newname"
                    git push "$remote" --delete "$branch"
                    echo -e "${GREEN}Renamed remote branch '$branch'  '$newname' on '$remote'.${RESET}"
                fi
            else
                echo -e "${RED}Invalid target. Use 'local' or 'remote'.${RESET}"
                return 0
            fi
            ;;
        *)
            echo -e "${RED}Invalid action. Use 'list', 'delete' or 'rename'.${RESET}"
            return 0
            ;;
    esac
}

# Create a new git branch with an optional prefix (default: feature)
gnew() {
    local prefix env name branch override=0

    # Parse -o option
    if [ "$1" = "-o" ]; then
        override=1
        shift
    fi

    if [ $override -eq 1 ]; then
        # -o means raw branch name (no prefix, no env)
        if [ $# -ne 1 ]; then
            echo "Usage: gbn -o <branch-name>"
            return 0
        fi
        branch="$1"
    else
        # Require prefix, env, and branch name
        if [ $# -ne 3 ]; then
            echo "Usage: gbn <prefix> <env> <branch-name>"
            echo "Examples:"
            echo "  gbn feat dev HELP-123     # -> feat/dev/HELP-123"
            echo "  gbn bugfix prd HELP-123   # -> bugfix/prd/HELP-123"
            echo "  gbn -o HELP-123           # -> HELP-123 (no prefix/env)"
            return 0
        fi
        prefix="$1"
        env="$2"
        name="$3"
        branch="${prefix}/${env}/${name}"
    fi

    echo "Creating and switching to branch: $branch"
    git checkout -b "$branch"
}

# ================================
#  Branch Checkout Helpers
# ================================
gco() {
    local flag_p=0
    local branch=""

    # Parse options
    while [[ "$1" == -* ]]; do
        case "$1" in
            -p) flag_p=1 ;;
            *) echo "Unknown option $1"; return 0 ;;
        esac
        shift
    done

    branch="$1"
    [ -z "$branch" ] && { echo "Usage: gco [-p] <branch>"; return 0; }

    # Save current branch
    local current_branch
    current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)

    if [[ "$branch" == "$current_branch" ]]; then
        echo "Already on branch '$branch'"
        return 0
    fi

    if [[ $flag_p -eq 1 ]]; then
        # Checkout target branch, pull, then return
        git checkout "$branch" || return 0
        git pull || return 0
        git checkout "$current_branch" || return 0
        echo "Pulled '$branch' and returned to '$current_branch'"
    else
        git checkout "$branch" || return 0
    fi
}
process() {
    RED='\033[0;31m'
    NC='\033[0m' # No Color

    # Get current branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [ -z "$branch" ]; then
        echo "Not on a branch"
        return 0
    fi

    # Expected format: type/env/ticket
    type=$(echo "$branch" | cut -d/ -f1)
    env=$(echo "$branch" | cut -d/ -f2)
    ticket=$(echo "$branch" | cut -d/ -f3-)

    # Select task type
    echo "Select task:"
    echo "1) feat"
    echo "2) chore"
    echo "3) fix"
    read -r task_choice
    case "$task_choice" in
        1) task="feat" ;;
        2) task="chore" ;;
        3) task="fix" ;;
        *) echo "Invalid choice"; return 0 ;;
    esac
    echo "Task Selected: $task"

    # Prompt for commit message
    echo "Enter commit message:"
    read -r msg
    [ -z "$msg" ] && { echo "Commit message cannot be empty"; return 0; }

    # Detect Terraform repo
    if git ls-files -- '*.tf' | grep -q '\.tf$' || [ -f "terraform.lock.hcl" ]; then
        echo "Terraform repo detected."
        echo "Running terraform fmt..."
        terraform fmt
        echo "Validating Terraform..."
        terraform validate || { echo "Terraform validation failed"; return 0; }
    fi

    # Stage all files
    echo "Adding all files..."
    git add .

    # Commit message format
    commit_msg="${task}: ${env}-${ticket}-${msg}"

    # Ask new commit or amend
    echo "Do you want to (n)ew commit or (a)mend last commit? [n/a]"
    read -r choice
    if [ "$choice" = "a" ]; then
        echo "Amending last commit..."
        git commit --amend -m "$commit_msg"
    else
        echo "Creating new commit..."
        git commit -m "$commit_msg"
    fi

    echo "Fetching latest branches..."
    git fetch origin

    # Only rebase onto feature branch if it exists
    feature_branch="origin/${type}/${env}"
    if git show-ref --verify --quiet "refs/remotes/$feature_branch"; then
        echo -e "${RED}Rebasing $branch onto $feature_branch...${NC}"
        git rebase "$feature_branch" || {
            echo "Rebase onto $feature_branch failed. Resolve conflicts manually."
            return 0
        }
    else
        echo "No remote feature branch found. Skipping feature rebase."
    fi

    # Rebase onto main
    echo -e "${RED}Rebasing $branch onto origin/main...${NC}"
    git rebase origin/main || {
        echo "Rebase onto origin/main failed. Resolve conflicts manually."
        return 0
    }

    # Push branch (try force-with-lease, fallback to force)
    echo -e "${RED}Pushing branch: $branch${NC}"
    git push --force-with-lease origin "$branch" || {
        echo "Force-with-lease failed, falling back to force push..."
        git push --force origin "$branch" || {
            echo "Push failed completely. Resolve issues manually."
            return 0
        }
    }

    echo "Rebase and push completed successfully. History is linear."
}


# ================================
#  Commit with branch prefix
# ================================
gc_branch_prefix() {

    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD)
    if [ -z "$branch" ]; then
        echo "Not on a branch"
        return 0
    fi

    # Extract prefix and ticket
    if [[ "$branch" =~ ^([^/]+)/(.+)$ ]]; then
        prefix="${BASH_REMATCH[1]}"
        ticket="${BASH_REMATCH[2]}"
        commit_prefix="$prefix: $ticket - "
    else
        commit_prefix=""
    fi

    if [ $# -eq 0 ]; then
        echo "Usage: gcp <commit message>"
        return 0
    fi

    git commit -m "$commit_prefix$*"

}

# ================================
#  Rebase onto any branch
# ================================
grebase() {
    local target="${1:-main}"
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null)

    [ -z "$branch" ] && { echo "Not on a branch"; return 0; }

    echo "You are on branch '$branch'."
    echo "Do you want to rebase '$branch' onto 'origin/$target'? [y/N]"
    read -r answer
    case "$answer" in
        [Yy]* )
            git fetch origin || { echo "Failed to fetch"; return 0; }
            git rebase "origin/$target" || { echo "Rebase failed"; return 0; }
            echo "Rebased '$branch' onto 'origin/$target'"
            ;;
        * )
            echo "Aborted"
            return 0
            ;;
    esac
}

# --- Force push local branch to remote ---
pushforce() {
    local remote_name=${1:-origin}
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    [ -z "$branch" ] && { echo "Not on a branch"; return 0; }

    echo " WARNING: This will overwrite remote branch '$branch' on '$remote_name'"
    echo "Do you want to continue? [y/N]"
    read -r answer
    case "$answer" in
        [Yy]* )
            git push "$remote_name" "$branch" --force-with-lease || {
                echo "Force push failed"
                return 0
            }
            echo " Force-pushed '$branch' to '$remote_name'"
            ;;
        * )
            echo "Aborted"
            return 0
            ;;
    esac
}

# --- Hard-sync local branch with remote ---
syncforce() {
    local remote_name=${1:-origin}
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    [ -z "$branch" ] && { echo "Not on a branch"; return 0; }

    echo " WARNING: This will overwrite your local branch '$branch' to match '$remote_name/$branch'"
    echo "Do you want to continue? [y/N]"
    read -r answer
    case "$answer" in
        [Yy]* )
            git fetch "$remote_name" || { echo "Fetch failed"; return 0; }
            git reset --hard "$remote_name/$branch" || { echo "Reset failed"; return 0; }
            echo " Local branch '$branch' synced to '$remote_name/$branch'"
            ;;
        * )
            echo "Aborted"
            return 0
            ;;
    esac
}

ghelp() { 
	githelp
}
# ================================
#  Colored Git Helper Menu
# ================================
githelp() {
    echo -e "\n\e[1;32m Git Helper Commands\e[0m\n"

    echo -e "\e[1;32m[ Workflow ]\e[0m"
    echo -e "  \e[1;36mmakepr\e[0m            Rebase onto your origin feature branch then rebase to origin main and make PR"
    echo -e "  \e[1;36mpreppr\e[0m            Do prepwork for the feature branch and squash multiple commit before makepr"
    echo -e "  \e[1;36mscf\e[0m               Show sample conflict & resolution procedure"
    echo -e "  \e[1;36mcfrs\e[0m              Check for merge conflict and launch vscode"

    echo -e "\n\e[1;32m[ Create / Status / Stage / Commit / Push ]\e[0m"
    echo -e "  \e[1;36mgbc\e[0m               Clone Repository e.g https://github.com/your_handle/your_repository_name"
    echo -e "  \e[1;36mgbn\e[0m               Create new branch with optional prefix (default: feat)"
    echo -e "  \e[1;36mgbs\e[0m               Branch Status"
    echo -e "  \e[1;36mga\e[0m                Stage files"
    echo -e "  \e[1;36mgau\e[0m               Unstage files"
    echo -e "  \e[1;36mgc\e[0m                Commit"
    echo -e "  \e[1;36mgp\e[0m                Push branch to remote"

    echo -e "\n\e[1;32m[ Logs / Diffs / Show ]\e[0m"
    echo -e "  \e[1;36mgl\e[0m                Pretty log"
    echo -e "  \e[1;36mgll\e[0m               Detailed log with colors"
    echo -e "  \e[1;36mgsh\e[0m               Show latest commit details"
    echo -e "  \e[1;36mgd\e[0m                Diff unstaged changes"
    echo -e "  \e[1;36mgds\e[0m               Diff staged changes"

    echo -e "\n\e[1;32m[ Blame / File History ]\e[0m"
    echo -e "  \e[1;36mgbbl <f>\e[0m          Show blame for file"
    echo -e "  \e[1;36mgbln <f> <line>\e[0m   Show blame for specific line"
    echo -e "  \e[1;36mgbls <f> <line>\e[0m   Show commit that changed line"
    echo -e "  \e[1;36mgblh <f> <line>\e[0m   Show history of a line"
    echo -e "  \e[1;36mgblr <f> [N]\e[0m      Blame limited to last N commits (default 5)"


    echo -e "\n\e[1;32m[ Branch Management ]\e[0m"
    echo -e "  \e[1;36mgman\e[0m              Branch Management"
    echo -e "  \e[1;36mgclean\e[0m            Auto remove feature local and remote (--remote) branch"
    echo -e "  \e[1;36mgbsan\e[0m             Auto-remove + commit ignored files"
    echo -e "  \e[1;36mgco\e[0m               Checkout branch (with -p perform git pull and return to previous branch)"
    echo -e "  \e[1;36mpushforce\e[0m         Force push local branch to remote (overwrites remote)"
    echo -e "  \e[1;36msyncforce\e[0m         Hard-sync local branch to match remote (overwrites local)"
    echo -e "  \e[1;36mnuke\e[0m              Nuke your origin main repository and resync files (VERY DESTRUCTIVE)"


    echo -e "\n\e[1;32m[ Commit Reset Option ]\e[0m"

    echo -e "  \e[1;36mgundo\e[0m             Undo last commit (keep staged)"
    echo -e "  \e[1;36mgundoh\e[0m            Undo last commit (unstage changes)"
    echo -e "  \e[1;36mgundoall\e[0m          Undo last commit (discard changes)"

    echo -e "\n\e[1;32m[ Stash Helpers ]\e[0m"
    echo -e "  \e[1;36mgstash\e[0m            Save stash (includes untracked)"
    echo -e "  \e[1;36mgstashm\e[0m           Save stash with message"
    echo -e "  \e[1;36mgstashl\e[0m           List stash entries"
    echo -e "  \e[1;36mgstasha\e[0m           Apply latest stash"
    echo -e "  \e[1;36mgstashp\e[0m           Pop latest stash"
    echo -e "  \e[1;36mgstashd\e[0m           Drop stash by ID"

    echo -e "\n\e[1;32m[ File Tracking ]\e[0m"
    echo -e "  \e[1;36mguntrack\e[0m          Stop tracking file but keep locally"
    echo -e "  \e[1;36mgcpy\e[0m              Copying files/asset within the branch"
    
    echo -e "\n\e[1;32m[ Remote / Upstream Helper ]\e[0m"
    echo -e "  \e[1;36msetreponame\e[0m       Rename Remote Repository"
    echo -e "  \e[1;36msetremote\e[0m         Add or update a remote URL"
    echo -e "  \e[1;36mpushup\e[0m            Push current branch and set upstream"
    echo -e "  \e[1;36mnewrepo\e[0m           Create GitHub repository"
    echo -e "  \e[1;36mremoteinfo\e[0m        Show remotes and upstream info"

    echo -e "\n Tip: Run \e[1;36mghelp\e[0m anytime to recall these shortcuts!\n"
}

duke_nukem() { 
    echo "WARNING: This will overwrite your remote 'origin $branch' and make a HARD RESET AND ZAP HISTORY"
    echo "Do you want to continue? [y/N]"
    read -r answer
    case "$answer" in
        [Yy]* )
	    git checkout --orphan temp_branch && git add -A && git commit -m "Initial commit" && git branch -D main && git branch -m main && git push -f origin main
	    git branch --set-upstream-to=origin/main main
	    echo "Done.... I hope you like it :)"
            ;;
        * )
            echo "Aborted"
            return 0
            ;;
    esac
}

REPO="$HOME/desktop/GIT"
echo "CD to your GIT workspace"
cd "$REPO" 2>/dev/null
cdmenu
echo "ghelp - for additional helper functions"


complete -C C:\WINDOWS\system32\terraform.exe terraform
