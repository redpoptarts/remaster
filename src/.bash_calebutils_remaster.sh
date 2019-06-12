function remaster() {
	clear && printf '\e[3J'
  printf "${White}"
  FullLine="\n${White}------------------------------------------------------"
  OK="✅ OK"
  Error="${Red}❌ ERROR"

	# ---- Check git configuration ----
  printf "${FullLine}"
  printf "\n${Green} Remaster - Initializing"
  printf "${FullLine}\n"
  # Store Current Branch Name
  {
	  originalBranchName=$(git rev-parse --abbrev-ref HEAD) &&
    originalHeadRef=$(git rev-parse HEAD) &&
    upstreamRef=$(git rev-parse $upstreamRemoteName/master) &&
    localMasterRef=$(git rev-parse $localBranchTrackingOriginMaster)
  } && {
    printf "\n${Green}Git Configuration ${OK}\n"
  } || {
    printf "\n${Error}: Remaster configuration is invalid for this repo."
    printf "\n${Yellow}You must have:"
    printf "\n${White} • ${Yellow}A remote called ${Purple}$upstreamRemoteName${Yellow} "
    printf "\n${White} • ${Yellow}A branch on that remote called ${Purple}master${Yellow} "
    printf "\n${White} • ${Yellow}A remote called ${Purple}$originRemoteName${Yellow} "
    printf "\n${White} • ${Yellow}A branch on that remote called ${Purple}$localBranchTrackingOriginMaster${Yellow} "
    printf "\n\n${Reset}"
    return
  }

	# ---- Verify clean working tree ----
  printf "${FullLine}"
  printf "\n${Green} Checking for Clean Work Tree"
  printf "${FullLine}\n"
  
  printf "\n${Green}Current working branch: ${Cyan}$originalBranchName\n\n"
  
  printf "${Grey}"
  git fetch --all
	if ! $(require_clean_work_tree) ; then
		return
  else
    printf "\n${Green}No local uncommitted changes ... ${OK} \n"
	fi

	# ---- origin/master ----
  printf "${FullLine}"
  printf "\n${Green} Synchronize ${Cyan}$originRemoteName/$localBranchTrackingOriginMaster ${Green}with ${Cyan}$upstreamRemoteName/master"
  printf "${FullLine}"
  printf "\n${Grey}"

	# Checkout origin/master
	git checkout $localBranchTrackingOriginMaster

	# Synchronize (ff/rebase) origin/master <-- upstream/master
  ff_or_rebase $upstreamRemoteName/master $localBranchTrackingOriginMaster

	# Check: Is origin ahead of upstream?
	if [ $(git rev-list --count $upstreamRemoteName/master..$localBranchTrackingOriginMaster) -ge 1 ]; then
		# Suggest saving work into feature branch @ origin/master
    printf "\n${Yellow}WARNING: origin/master is AHEAD of upstream/master!\n"
		printf "\n${Yellow}Problem: You are developing on your master branch, which is not recommended."
    printf "\n\n${Green}Summary of commits:\n"
	  git log $upstreamRemoteName/master..$localBranchTrackingOriginMaster --graph --oneline
		printf "\n${Cyan}Recommended Solution: Would you like to save this work into a feature branch? (y/n) ${Grey}"
		read -s -n1 key
		case "$key" in
      [yY]) # Save progress to a feature branch
        printf "\n${Cyan}New feature branch name: ${Grey}"
        read choiceBranchName
        if check_valid_branch $choiceBranchName ; then
          printf "\n${Green}$choiceBranchName is a valid branch name ... ${OK}\n${Grey}"
			    # Save commits from origin/master into a feature branch
          git branch $choiceBranchName
          # Reset origin/master <== upstream/master
          git fetch $upstreamRemoteName +master:$localBranchTrackingOriginMaster --update-head-ok
          git push $originRemoteName $localBranchTrackingOriginMaster:master --force
        else
          printf "\n${Error}: ${Cyan}$choiceBranchName ${Red}is not a valid branch name.\n"
          printf "\n${Red}Feature Branch creation cancelled.  ${Cyan}$originRemoteName/$localBranchTrackingOriginMaster ${Yellow}will remain untouched.\n"
        fi
				;;
			* ) # Do nothing
          printf "\n${Yellow}Feature Branch creation cancelled.  ${Cyan}$originRemoteName/$localBranchTrackingOriginMaster ${Yellow}will remain untouched.\n"
				;;
			esac
	fi

  if [ "$originalBranchName" != "$localBranchTrackingOriginMaster" ]; then
    # ---- Feature Branch ----
    printf "${FullLine}"
    printf "\n${Green} Synchronize ${Cyan}$originalBranchName ${Green}with ${Cyan}$upstreamRemoteName/master"
    printf "${FullLine}"
    printf "\n${Grey}"

    # Restore HEAD from reference
    git checkout $originalBranchName || git checkout $originalHeadRef

    commitsAhead=$(git rev-list --right-only --count $upstreamRemoteName/master..$originalBranchName)
    commitsBehind=$(git rev-list --right-only --count $originalBranchName..$upstreamRemoteName/master)
    isAncestorOfUpstream=$(git merge-base --is-ancestor $upstreamRemoteName/master $originalBranchName)

    declare -a allRemoteRefs=$(git ls-remote --refs upstream 'pull/*/head' | cut -f1)
    unset foundPullRequest
    for ref in ${allRemoteRefs}; do
      if [ "$ref" = "$originalHeadRef" ]; then
        foundPullRequest=$ref
        isPullRequestMerged=$(git merge-base --is-ancestor $upstreamRemoteName/master $ref)
      fi
    done

    printf "\n${Green}Last commit on this branch: ${Purple}$(git show -s --format=%ar $originalHeadRef)"

    if [ "$originalHeadRef" = "$upstreamRef" ]; then
      printf "\n${Green}Your feature branch ${Cyan}$originalBranchName ${Green}is already equal to ${Cyan}upstream/master${Green}\n"
    else
      printf "\n\n${Green}This branch is ${Purple}$commitsAhead commits ahead ${Green}of $upstreamRemoteName/master"
      if [ "$commitsAhead" -gt 0 ]; then
        printf "\n"
        git log $upstreamRemoteName/master..$originalBranchName --graph --oneline
      fi

      printf "\n${Green}This branch is ${Purple}$commitsBehind commits behind ${Green}$upstreamRemoteName/master"
      if [ "$commitsBehind" -gt 0 ]; then
        printf "\n"
        git log $originalBranchName..$upstreamRemoteName/master --graph --oneline
      fi

      if [ "$commitsAhead" -gt 0 ]; then
        printf "\n${Red}NOTE: You have progress on ${Cyan}$originalBranchName ${Red}which has not been merged into ${Cyan}upstream/master${Reset}\n"
      fi
      
      if [ -n "$foundPullRequest" ]; then
        printf "\n${Red}NOTE: A pull request was found for this branch."
        if [ "$commitsAhead" -eq 0 ]; then
          printf "\n${Yellow}Merge Status: ${Purple}MERGED${Reset}"
          printf "\n\n${Green}Suggest creating a new branch ${White}(${Yellow} Option 2 ${White})${Reset}\n"
        else
          printf "\n${Yellow}Merge Status: ${Purple}UNMERGED / UNKNOWN${Reset}"
          printf "\n\n${Yellow}If this repo ${Cyan}merges${Yellow} PRs, then this PR has not been merged"
          printf "\n${Yellow}If this repo ${Cyan}squashes${Yellow} PRs, then the merge status cannot be determined.\n"
        fi
      fi

      # Ask user what to do with current progress on feature branch
      printf "\n${Green}Please make a selection:"
      printf "\n${White}(${Yellow} 1 ${White}) Rebase this branch (${Cyan}$originalBranchName${White}) onto ${Cyan}upstream/master${Yellow}"
      printf "\n${White}(${Yellow} 2 ${White}) Begin working on a new feature branch, from ${Cyan}upstream/master${Yellow}"
      printf "\n${White}(${Yellow} 3 ${White}) Do nothing.  Continue working on this branch (${Cyan}$originalBranchName${White})"
      printf "\n${Cyan}Branch Decision 1, 2, (3): ${Grey}"
      read -s -n1 key
      printf "\n"
      case "$key" in
        1) # Fast-Forward or Rebase feature branch
          ff_or_rebase $upstreamRemoteName/master $originalBranchName
          ;;
        2) # Create a new feature branch at upstream/master
          printf "\n${Cyan}New feature branch name: ${Grey}"
          read choiceBranchName
          if check_valid_branch $choiceBranchName ; then
            printf "\n${Green}$choiceBranchName is a valid branch name ... ${OK}\n"
            # Create branch @ upstream/master
            git checkout -b $choiceBranchName $upstreamRemoteName/master --no-track
            printf "\n\n${Green}You are in sync with ${Cyan}$upstreamRemoteName/master${Green} and are ready to begin working on your new feature, on branch ${Cyan}$choiceBranchName\n"
          else
            printf "\n${Error}: ${Cyan}$choiceBranchName ${Red}is not a valid branch name.\n"
            printf "\n${Red}Feature Branch creation cancelled.  ${Cyan}$originalBranchName ${Yellow}will remain checked out.\n"
          fi
          ;;
        * ) # Do nothing
            printf "\n${Yellow}Feature Branch will not be created.  ${Cyan}$originalBranchName ${Yellow}will remain checked out.\n"
          ;;
      esac
    fi
  fi

	# ---- Auto Yarn / NPM Install ----
  printf "${FullLine}"
  printf "\n${Green} Auto Update Dependencies"
  printf "${FullLine}"
  printf "\n${Grey}"
	# Check if there are any incoming changes to package.json
	git diff $originalHeadRef..HEAD --quiet --exit-code -- 'package.json'
	numPackageChanges=$?
  if [ $numPackageChanges -ne 0 ]; then
    if [ -f "yarn.lock" ]; then
      installCommand="yarn"
    else
      installCommand="npm install"
    fi
    
    printf "\n${Yellow}Changes have been detected in ${Purple}package.json${Yellow}, automatically running ${Purple}${installCommand}${Yellow}...\n\n"
    $installCommand && printf "\n${Green}Dependencies have been updated ... ${OK}\n\n" \
      || { printf "\n${Error}: Encountered a problem while running $installCommand\n\n"; }
  else
    printf "\n${Green}No changes detected in ${Purple}package.json${Green} ... ${OK}\n\n"
  fi

	# ---- Final Status ----
  printf "${FullLine}"
  printf "\n${Green} Final Branch Status"
  printf "${FullLine}"
  printf "\n${Grey}"
	
  finalBranchName=$(git rev-parse --abbrev-ref HEAD)
  commitsAhead=$(git rev-list --right-only --count $upstreamRemoteName/master..HEAD)
  commitsBehind=$(git rev-list --right-only --count HEAD..$upstreamRemoteName/master)

  printf "${Green}Current working branch: ${Cyan}$finalBranchName\n\n"
	git log -5 --graph --oneline
  printf "\n\n${Reset}"

  if [ "$autoOpenVSCodeOnShortcut" = "true" ]; then
		code .
	fi
}

ff_or_rebase() {
  rebaseBaseBranch=${1}
  branchToRebase=${2}

  {
    if [ -z $rebaseBaseBranch ] || [ -z $branchToRebase ]; then
      printr "\n${Error}: Must specify a branch to rebase, and a base to rebase onto."
      return
    fi
    baseBranchRef=$(git rev-parse $branchToRebase)
    rebaseBranchRef=$(git rev-parse $rebaseBaseBranch)

    {
      if [ "$baseBranchRef" = "$rebaseBranchRef" ]; then
        printf "\n${Green}Your branch ${Cyan}$branchToRebase ${Green}is already equal to ${Cyan}$rebaseBaseBranch${Green}.\n"
        true;
      else
        printf "\n${Green}Attempt to fast-foward, otherwise rebase...${Grey}\n"
        # Try to fast forward
        git merge $rebaseBaseBranch --ff-only && printf "\n${Green}Branch fast-forwarded: ${Cyan}$branchToRebase";
      fi
    } || {
      # Try to rebase
      git rebase $rebaseBaseBranch $branchToRebase && printf "\n${Green}Branch rebased: ${Cyan}$branchToRebase ${Green}(onto ${Cyan}$rebaseBaseBranch${Green})" \
      || {
        # Recover on error
        printf "\n${Yellow}Aborting auto-rebase... " && git rebase --abort && printf "${Yellow}Done\n" && false;
      }
    } && {
      # On general success
      printf "\n${Green}Sync complete ... ${OK}\n\n";
    }
  } || {
    # On any error
    printf "\n${Error}: Could not sync branch.\n\n";
  }
}

require_clean_work_tree () {
	# Update the index
	git update-index -q --ignore-submodules --refresh

	# Disallow unstaged changes in the working tree
  if [[ -n "$(git status --porcelain)" ]] || ! $(git diff-index --quiet --exit-code HEAD --) ; then
		echo -en >&2 "\n${Error}: Your local filesystem contains uncommitted changes.\n${Cyan}"
		git status -- >&2
		echo -en >&2 "\n${Yellow}Please commit or stash them, and try again.\n\n${Reset}"
		exit 1
	fi
}

check_valid_branch() {
  git check-ref-format --normalize "refs/heads/$1"
}
