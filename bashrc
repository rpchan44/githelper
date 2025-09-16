# ================================
#  Git Bash Helper Aliases & Functions
# ================================
if [ -f ~/.git-completion.bash ]; then
        . ~/.git-completion.bash
fi
# --- WORKFLOW ---
alias gflow="workflow"
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
alias gbl='gblame'          # full file blame
alias gbln='gblame_line'    # blame specific line
alias gbls='gblame_show'    # show commit for line
alias glh='gline_history'   # line history
alias gblr='gblame_recent'  # blame last N commits


# --- Branch Management ---
alias gbc="echo Cloning Repository; git clone "
alias gcomp="gacp"
alias gman='gbmanage'
alias gpf='echo Push your local to remote (no matter what); pushforce'
alias gsf='echo Pull your remote branch to your local (no matter what); syncforce'

# --- Rebasing / Resetting ---
alias gcr='echo Rebasing HEAD with last 5 commits; git rebase -i HEAD~5'
alias gra='echo Git rebase ABORT; git rebase --abort'
alias grc='echo Git rebase continue; git rebase --continue'
alias gundo='echo Undo last commit (keep changes staged); git reset --soft HEAD~1'
alias gundoh='echo Undo last commit (unstage changes, keep edits); git reset --mixed HEAD~1'
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


# ================================
#  Directory Menu Helper
# ================================
cdmenu() {
    dirs=(*/)
    [ ${#dirs[@]} -eq 0 ] && { echo "No subdirectories found"; return 1; }
    echo "Select a directory:"
    select d in "${dirs[@]}"; do
        [ -n "$d" ] && cd "$d" && break
        echo "Invalid choice"
    done
}

# ================================
#  Remote Repo Helpers
# ================================
setremote() {
    [ $# -ne 2 ] && { echo "Usage: setremote <remote_name> <url>"; return 1; }
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

workflow() { 
    echo "-=-=-=-=-=-=-=-=-=-=-GIT WORKFLOW=-=-=-=-=-=-=-=-=-="
    echo -e "THIS IS APPLICABLE ONLY FOR A REPOSITORY THAT'S ALREADY EXISTED ON YOUR LOCAL COMPUTER\n"
    echo "Before creating a feature branch out of main branch of a specific repository issue gco -p main"
    echo -e "This will allows you to update the main repository code before you make your own branch this is very important\n"
    echo -e "e.g run\ngco -p main; gbn HELP-123\n"
    echo -e "Under the hood this will make a git pull on the main branch of that repository and create a branch name feat/HELP-123\n"
}
pushup() {
    local remote_name=${1:-origin}
    local branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD)
    [ -z "$branch" ] && { echo "Not on a branch"; return 1; }
    echo "Pushing branch '$branch' to remote '$remote_name'"
    git push -u "$remote_name" "$branch"
}

# ========================================
# Copy files within current Git branch
# Usage: gcopy <source> <destination>
# ========================================
gcpy() {
    if ! git rev-parse --show-toplevel &>/dev/null; then
        echo "Not inside a Git repository"
        return 1
    fi

    local repo_root
    repo_root=$(git rev-parse --show-toplevel)
    repo_root=$(cygpath -u "$repo_root")   # normalize → /c/Users/...

    if [[ $# -lt 2 ]]; then
        echo "Usage: gcpy <source...> <destination>"
        return 1
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
                echo "DEBUG: abs_src=$abs_src"
                echo "DEBUG: repo_root=$repo_root"
                shopt -u nocasematch
                return 1
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
        return 1
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
    [ -z "$file" ] && { echo "Usage: gblame <file>"; return 1; }
    git blame "$file"
}

gblame_line() {
    local file=$1 line=$2
    [ -z "$file" ] || [ -z "$line" ] && { echo "Usage: gblame_line <file> <line>"; return 1; }
    git blame -L "$line","$line" "$file"
}

gblame_show() {
    local file=$1 line=$2
    [ -z "$file" ] || [ -z "$line" ] && { echo "Usage: gblame_show <file> <line>"; return 1; }
    local commit=$(git blame -L "$line","$line" --porcelain "$file" | awk '/^commit/ {print $2}')
    echo " Commit for $file line $line: $commit"
    git show "$commit"
}

gline_history() {
    local file=$1 line=$2
    [ -z "$file" ] || [ -z "$line" ] && { echo "Usage: gline_history <file> <line>"; return 1; }
    git log -L "$line","$line":"$file"
}

gblame_recent() {
    local file=$1 count=${2:-5}
    [ -z "$file" ] && { echo "Usage: gblame_recent <file> [N_commits]"; return 1; }
    local range="HEAD~$count..HEAD"
    echo " Blaming $file for last $count commits ($range)"
    git blame "$range" -- "$file"
}


ghcreate() {
    local repo_name visibility url

    repo_name=$1
    visibility=${2:-private}

    [ -z "$repo_name" ] && { echo "Usage: ghcreate <repo_name> [private|public]"; return 1; }

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
    [ -z "$branch" ] && { echo "Not on a branch"; return 1; }
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
        return 1
    fi

    # Validate repo
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo -e "${RED}Not inside a Git repository.${RESET}"
        return 1
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
                    return 1
                    ;;
            esac
            ;;
        delete)
            if [[ "$target" == "local" ]]; then
                if ! git show-ref --verify --quiet "refs/heads/$branch"; then
                    echo -e "${RED}Local branch '$branch' does not exist.${RESET}"
                    return 1
                fi
                if [[ "$(git rev-parse --abbrev-ref HEAD)" == "$branch" ]]; then
                    echo -e "${RED}You cannot delete the branch you are currently on.${RESET}"
                    return 1
                fi
                echo -e "${YELLOW}Delete local branch '$branch'? (y/N)${RESET}"
                read -r ans
                [[ "$ans" =~ ^[Yy]$ ]] && git branch -D "$branch" \
                    && echo -e "${GREEN}Deleted local branch '$branch'.${RESET}"

            elif [[ "$target" == "remote" ]]; then
                local remote=$(git remote | head -n1)
                if [[ -z "$remote" ]]; then
                    echo -e "${RED}No remote configured.${RESET}"
                    return 1
                fi
                if ! git ls-remote --heads "$remote" "$branch" | grep -q .; then
                    echo -e "${RED}Remote branch '$branch' not found on '$remote'.${RESET}"
                    return 1
                fi
                echo -e "${YELLOW}Delete remote branch '$branch' from '$remote'? (y/N)${RESET}"
                read -r ans
                [[ "$ans" =~ ^[Yy]$ ]] && git push "$remote" --delete "$branch" \
                    && echo -e "${GREEN}Deleted remote branch '$branch' from '$remote'.${RESET}"
            else
                echo -e "${RED}Invalid target. Use 'local' or 'remote'.${RESET}"
                return 1
            fi
            ;;
        rename)
            if [[ -z "$newname" ]]; then
                echo -e "${RED}Missing new branch name.${RESET}"
                return 1
            fi
            if [[ "$target" == "local" ]]; then
                if ! git show-ref --verify --quiet "refs/heads/$branch"; then
                    echo -e "${RED}Local branch '$branch' does not exist.${RESET}"
                    return 1
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
                    return 1
                fi
                if ! git ls-remote --heads "$remote" "$branch" | grep -q .; then
                    echo -e "${RED}Remote branch '$branch' not found on '$remote'.${RESET}"
                    return 1
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
                return 1
            fi
            ;;
        *)
            echo -e "${RED}Invalid action. Use 'list', 'delete' or 'rename'.${RESET}"
            return 1
            ;;
    esac
}
# Create a new git branch with an optional prefix (default: feature)
gnew() {
    local prefix name branch override=0

    # Parse -o option
    if [ "$1" = "-o" ]; then
        override=1
        shift
    fi

    if [ $# -eq 1 ]; then
        if [ $override -eq 1 ]; then
            branch=$1
        else
            prefix="feat"
            name=$1
            branch="${prefix}/${name}"
        fi
    elif [ $# -eq 2 ]; then
        if [ $override -eq 1 ]; then
            branch=$1  # when using -o, treat first argument as full branch name
        else
            prefix=$1
            name=$2
            branch="${prefix}/${name}"
        fi
    else
        echo "Usage: gnew [-o] [prefix] <branch-name>"
        echo "Examples:"
        echo "  gnew HELP-123         # -> feat/HELP-123"
        echo "  gnew bugfix HELP-123  # -> bugfix/HELP-123"
        echo "  gnew -o HELP-123      # -> HELP-123 (no prefix)"
        return 1
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
            *) echo "Unknown option $1"; return 1 ;;
        esac
        shift
    done

    branch="$1"
    [ -z "$branch" ] && { echo "Usage: gco [-p] <branch>"; return 1; }

    # Save current branch
    local current_branch
    current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)

    if [[ "$branch" == "$current_branch" ]]; then
        echo "Already on branch '$branch'"
        return 0
    fi

    if [[ $flag_p -eq 1 ]]; then
        # Checkout target branch, pull, then return
        git checkout "$branch" || return 1
        git pull || return 1
        git checkout "$current_branch" || return 1
        echo "Pulled '$branch' and returned to '$current_branch'"
    else
        git checkout "$branch" || return 1
    fi
}

gacp() {
    # Get current branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [ -z "$branch" ]; then
        echo " Not on a branch"
        return 1
    fi

    # Extract prefix and ticket (split at "/")
    type=$(echo "$branch" | cut -d/ -f1)
    ticket=$(echo "$branch" | cut -d/ -f2-)

    # Fallbacks
    [ -z "$type" ] && type="chore"
    [ -z "$ticket" ] && ticket="$branch"

    # User message
    local msg=$*
    if [ -z "$msg" ]; then
        echo "Usage: gcomp <commit-message>"
        echo "Example: gcomp \"My Commit Message\""
        return 1
    fi

    # Final commit message
    commit_msg="${type}: ${ticket} - ${msg}"

    echo " Adding all files..."
    git add .

    echo " Committing: $commit_msg"
    git commit -m "$commit_msg"

    echo "  Pushing branch: $branch"
    git push -u origin "$branch"
}


gcb() {
    if command -v fzf &>/dev/null; then
        local branch=$(git branch --all | sed 's/^[* ] //' | fzf --height 40% --reverse --border)
    else
        echo "fzf not found. Listing branches numerically:"
        mapfile -t branches < <(git branch --all | sed 's/^[* ] //')
        select branch in "${branches[@]}"; do
            [ -n "$branch" ] && break
        done
    fi
    [ -z "$branch" ] && { echo "No branch selected"; return 1; }
    gco "$branch"
}

# ================================
#  Commit with branch prefix
# ================================
gc_branch_prefix() {

    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD)
    if [ -z "$branch" ]; then
        echo "Not on a branch"
        return 1
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
        return 1
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

    [ -z "$branch" ] && { echo "Not on a branch"; return 1; }

    echo "You are on branch '$branch'."
    echo "Do you want to rebase '$branch' onto 'origin/$target'? [y/N]"
    read -r answer
    case "$answer" in
        [Yy]* )
            git fetch origin || { echo "Failed to fetch"; return 1; }
            git rebase "origin/$target" || { echo "Rebase failed"; return 1; }
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
    [ -z "$branch" ] && { echo "Not on a branch"; return 1; }

    echo " WARNING: This will overwrite remote branch '$branch' on '$remote_name'"
    echo "Do you want to continue? [y/N]"
    read -r answer
    case "$answer" in
        [Yy]* )
            git push "$remote_name" "$branch" --force-with-lease || {
                echo "Force push failed"
                return 1
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
    [ -z "$branch" ] && { echo "Not on a branch"; return 1; }

    echo " WARNING: This will overwrite your local branch '$branch' to match '$remote_name/$branch'"
    echo "Do you want to continue? [y/N]"
    read -r answer
    case "$answer" in
        [Yy]* )
            git fetch "$remote_name" || { echo "Fetch failed"; return 1; }
            git reset --hard "$remote_name/$branch" || { echo "Reset failed"; return 1; }
            echo " Local branch '$branch' synced to '$remote_name/$branch'"
            ;;
        * )
            echo "Aborted"
            return 0
            ;;
    esac
}

ghelp() { 
	githelp | less -RPs'[Press q to quit help] '
}
# ================================
#  Colored Git Helper Menu
# ================================
githelp() {
    echo -e "\n\e[1;32m Git Helper Commands\e[0m\n"

    echo -e "\e[1;32m[ GitWork Flow (README) ]\e[0m"
    echo -e "  \e[1;36mgflow\e[0m     Show basic git workflow"

    echo -e "\n\e[1;32m[ Create / Status / Stage / Commit / Push ]\e[0m"
    echo -e "  \e[1;36mgbc\e[0m       Clone Repository e.g https://github.com/your_handle/your_repository_name"
    echo -e "  \e[1;36mgbn\e[0m       Create new branch with optional prefix (default: feat)"
    echo -e "  \e[1;36mgbs\e[0m       Branch Status"
    echo -e "  \e[1;36mga\e[0m        Stage files"
    echo -e "  \e[1;36mgau\e[0m       Unstage files"
    echo -e "  \e[1;36mgc\e[0m        Commit"
    echo -e "  \e[1;36mgp\e[0m        Push branch to remote"

    echo -e "\n\e[1;32m[ Logs / Diffs / Show ]\e[0m"
    echo -e "  \e[1;36mgl\e[0m        Pretty log"
    echo -e "  \e[1;36mgll\e[0m       Detailed log with colors"
    echo -e "  \e[1;36mgsh\e[0m       Show latest commit details"
    echo -e "  \e[1;36mgd\e[0m        Diff unstaged changes"
    echo -e "  \e[1;36mgds\e[0m       Diff staged changes"

    echo -e "\n\e[1;32m[ Blame / File History ]\e[0m"
    echo -e "  \e[1;36mgblame <file>\e[0m                Show blame for file"
    echo -e "  \e[1;36mgblame_line <f> <line>\e[0m       Show blame for specific line"
    echo -e "  \e[1;36mgblame_show <f> <line>\e[0m       Show commit that changed line"
    echo -e "  \e[1;36mgline_history <f> <line>\e[0m     Show history of a line"
    echo -e "  \e[1;36mgblame_recent <f> [N]\e[0m        Blame limited to last N commits (default 5)"


    echo -e "\n\e[1;32m[ Branch Management ]\e[0m"
    echo -e "  \e[1;36mgman\e[0m      Branch Management"
    echo -e "  \e[1;36mgcomp\e[0m     Stage + Commit + Push (All-in-One)"
    echo -e "  \e[1;36mgco\e[0m       Checkout branch (with -p perform git pull and return to previous branch)"
    echo -e "  \e[1;36mgcb\e[0m       Interactive checkout"
    echo -e "  \e[1;36mpushforce\e[0m  Force push local branch to remote (overwrites remote)"
    echo -e "  \e[1;36msyncforce\e[0m  Hard-sync local branch to match remote (overwrites local)"


    echo -e "\n\e[1;32m[ Rebasing / Resetting ]\e[0m"
    echo -e "  \e[1;36mgcr\e[0m       Rebase last 5 commits interactively"
    echo -e "  \e[1;36mgra\e[0m       Abort rebase"
    echo -e "  \e[1;36mgrc\e[0m       Continue rebase"
    echo -e "  \e[1;36mgrebase\e[0m   Rebase current branch onto main (or specified)"

    echo -e "  \e[1;36mgundo\e[0m     Undo last commit (keep staged)"
    echo -e "  \e[1;36mgundoh\e[0m    Undo last commit (unstage changes)"
    echo -e "  \e[1;36mgundoall\e[0m  Undo last commit (discard changes)"

    echo -e "\n\e[1;32m[ Stash Helpers ]\e[0m"
    echo -e "  \e[1;36mgstash\e[0m    Save stash (includes untracked)"
    echo -e "  \e[1;36mgstashm\e[0m   Save stash with message"
    echo -e "  \e[1;36mgstashl\e[0m   List stash entries"
    echo -e "  \e[1;36mgstasha\e[0m   Apply latest stash"
    echo -e "  \e[1;36mgstashp\e[0m   Pop latest stash"
    echo -e "  \e[1;36mgstashd\e[0m   Drop stash by ID"

    echo -e "\n\e[1;32m[ File Tracking ]\e[0m"
    echo -e "  \e[1;36mguntrack\e[0m  Stop tracking file but keep locally"
    echo -e "  \e[1;36mgcpy\e[0m      Copying files/asset within the branch"

    echo -e "\n\e[1;32m[ Remote / Upstream Helper ]\e[0m"
    echo -e "  \e[1;36msetremote\e[0m  Add or update a remote URL"
    echo -e "  \e[1;36mpushup\e[0m     Push current branch and set upstream"
    echo -e "  \e[1;36mghcreate\e[0m   Create GitHub repo and push"
    echo -e "  \e[1;36mremoteinfo\e[0m  Show remotes and upstream info"

    echo -e "\n Tip: Run \e[1;36mghelp\e[0m anytime to recall these shortcuts!\n"
}

REPO="$HOME/desktop/GIT"
echo "CD to your GIT workspace"
cd "$REPO" 2>/dev/null
cdmenu
echo "ghelp - for additional helper functions"

