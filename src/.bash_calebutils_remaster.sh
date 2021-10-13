#!bin/bash/sh

function remaster() {
  clear && printf '\e[3J'
  printf "${White}"
  FullLine="\n${White}------------------------------------------------------"
  OK="${Green}✅ OK"
  Warning="${Yellow}⚠️  WARNING"
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
    localMasterRef=$(git rev-parse $localBranchTrackingOriginMaster) &&
    repoName=basename `git rev-parse --show-toplevel`
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
  if ! $(require_clean_work_tree) ; then
    return
  else
    printf "\n${Green}No local uncommitted changes ... ${OK} \n"
  fi
  git fetch --all

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
    read -q -n 1 key
    case "$key" in
      [yY]) # Save progress to a feature branch
        create_custom_branch "ConfirmOverwrite" # Stores selected branch name in variable $choiceBranchName
        {
          # Save commits from origin/master into a feature branch
          # Reset origin/master <== upstream/master (force)
          printf "\n${Green}Resetting ${Cyan}${localBranchTrackingOriginMaster}${Green} to equal ${Cyan}$upstreamRemoteName/master${Green}...\n${Grey}"
          git fetch $upstreamRemoteName +master:$localBranchTrackingOriginMaster && \
          git push $originRemoteName +$localBranchTrackingOriginMaster:master
        } && {
          printf "\n${OK}: Forced reset of ${Cyan}${localBranchTrackingOriginMaster}${Green}, locally and on remote ${Cyan}$originRemoteName \n${Grey}"
          printf "\n${OK}: Saved progress into new feature branch (${Purple} ${choiceBranchName} ${Green})\n"
          originalBranchName=$choiceBranchName
        } || {
          printf "\n${Error}: Error saving progress into new branch \n"
          printf "\n${Red}Feature Branch creation cancelled.  ${Cyan}$originRemoteName/$localBranchTrackingOriginMaster ${Yellow}will remain untouched.\n${Grey}"
          git checkout $originalBranchName
        }
        ;;
      * ) # Do nothing
          printf "\n${Yellow}Feature Branch creation cancelled.  ${Cyan}$originRemoteName/$localBranchTrackingOriginMaster ${Yellow}will remain untouched.\n"
        ;;
      esac
  fi

  # ---- Feature Branch ----
  if [ "$originalBranchName" = "$localBranchTrackingOriginMaster" ]; then
    printf "${FullLine}"
    printf "\n${Green} Synchronize feature branch"
    printf "${FullLine}"

    printf "\n${Yellow}You do not currently have a feature branch checked out."
    printf "\n${Yellow}Current branch: ${Purple}$originalBranchName\n\n${Green}"
  fi

  if [ "$originalBranchName" = "HEAD" ]; then
    printf "${FullLine}"
    printf "\n${Green} Synchronize ${Cyan}${originalBranchName}${Green} with ${Cyan}$upstreamRemoteName/master"
    printf "${FullLine}"

    git checkout $originalHeadRef --quiet

    printf "\n\n${Warning} You are in a detached head state! (You do not have any branch checked out)\n"
    printf "\n${Green}Here's a list of all branch names and tags that also point to your current commit:"
    printf "\n${Purple}"

    git log -n1 --format=%D `# Output all branch names for the current commit` \
      | tr -d " " | cut -d"," -f 2- `# Exclude 'HEAD' from output` \
      | tr , "\n" `# Output on separate lines`

    printf "\n${Cyan}Recommend solution: Checkout/Create a branch at this location? (y/N) ${Grey}"
    read -q -n 1 key
    case "$key" in
      [yY])
        create_custom_branch "Any"
        originalBranchName=$choiceBranchName
        ;;
      *)
        printf "\n${Yellow}Feature Branch will not be created.  ${Cyan}$originalBranchName ${Yellow}will remain checked out.\n"
        ;;
    esac
  fi
  
  if [ "$originalBranchName" != "HEAD" ] && [ "$originalBranchName" != "$localBranchTrackingOriginMaster" ]; then
    printf "${FullLine}"
    printf "\n${Green} Synchronize ${Cyan}$originalBranchName ${Green}with ${Cyan}$upstreamRemoteName/master"
    printf "${FullLine}"
    printf "\n${Grey}"
    # Restore HEAD from reference
    git checkout $originalBranchName || git checkout $originalHeadRef

    commitsAhead=$(git rev-list --right-only --count $upstreamRemoteName/master..$originalBranchName)
    commitsBehind=$(git rev-list --right-only --count $originalBranchName..$upstreamRemoteName/master)
    isUpstreamAncestorOfFeature=$(git merge-base --is-ancestor $upstreamRemoteName/master $originalBranchName; echo $?)
    isFeatureAncestorOfUpstream=$(git merge-base --is-ancestor $originalBranchName $upstreamRemoteName/master; echo $?)

    # Check for existing pull request
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
      
      printf "\n"
      if [ -n "$foundPullRequest" ]; then
        printf "\n${Green}Pull Request Status: ${Green}FOUND"
        if [ "$commitsAhead" -eq 0 ]; then
          printf "\n${Green}Merge Status: ${Green}MERGED${Reset}"
          printf "\n\n${Green}Suggest creating a new branch ${White}(${Yellow} Option 2 ${White})${Reset}\n"
        else
          printf "\n${Green}Merge Status: ${Red}UNMERGED / UNKNOWN${Reset}"
          printf "\n\n${Yellow}If this repo ${Cyan}merges${Yellow} PRs, then this PR has not been merged"
          printf "\n${Yellow}If this repo ${Cyan}squashes${Yellow} PRs, then the merge status cannot be determined.\n"
        fi
      else
        if [ "$commitsAhead" -gt 0 ]; then
          printf "\n${Green}Pull Request Status: ${Red}NOT FOUND"
          printf "\n${Yellow}NOTE: You have progress on ${Cyan}$originalBranchName ${Yellow}which has not been merged into ${Cyan}upstream/master${Reset}\n"
        fi
      fi

      if [[ "$commitsBehind" -eq 0 || "$3" -eq 0 ]]; then
        # Ask user what to do with current progress on feature branch

        # Highlight options which could be useful
        declare -a optionColor
        optionColor[1]=${Grey}
        optionColor[2]=${Grey}
        if [[ "$commitsBehind" -gt 0 ]]; then
          optionColor[1]=${White}
        fi
        if [[ "$isFeatureAncestorOfUpstream" -eq 0 ]]; then
          optionColor[2]=${White}
        fi

        printf "\n${Green}Please make a selection:"
        printf "\n${optionColor[1]}(${Yellow} 1 ${optionColor[1]}) ${Purple}SYNC BRANCH${optionColor[1]} - Rebase this branch (${Cyan}$originalBranchName${optionColor[1]}) onto ${Cyan}upstream/master${Yellow}"
        printf "\n${optionColor[2]}(${Yellow} 2 ${optionColor[2]}) ${Purple}NEW FEATURE${optionColor[2]} - Begin working on a new feature branch, from ${Cyan}upstream/master${Yellow}"
        printf "\n${White}(${Yellow} 3 ${White}) ${Purple}DO NOTHING${optionColor[1]} - Continue working on this branch (${Cyan}$originalBranchName${White})"
        printf "\n${Cyan}Branch Decision 1, 2, (3): ${Grey}"
        read -q -n 1 key
        printf "\n"
        case "$key" in
          1) # Fast-Forward or Rebase feature branch
            ff_or_rebase $upstreamRemoteName/master $originalBranchName
            ;;
          2) # Create a new feature branch at upstream/master
            printf "\n${Cyan}New feature branch name: ${Grey}"
            read choiceBranchName
            if check_valid_branch $choiceBranchName "ConfirmOverwrite"; then
              printf "\n${Grey}'$choiceBranchName' is a valid branch name\n${Grey}"
              # Create branch @ upstream/master
              git checkout -B $choiceBranchName $upstreamRemoteName/master --no-track
              printf "\n${OK}: Feature branch created and switched successfully.\n"
              push_and_set_upstream_if_config_enabled
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

  # ---- Quick Links ----
  printf "${FullLine}"
  printf "\n${Green} Quick Links"
  printf "${FullLine}"
  printf "\n%-10s" "abc123" "http://www.github.com/${orgGithub}/${repoName}/compare/master...${githubUsername}:${originalBranchName}"

  if [ "$autoOpenVSCodeOnShortcut" = "true" ]; then
    code .
  fi

  printf "\n\n${Reset}"
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

create_custom_branch() {
  ruleAllowExisting=${1}

  printf "\n${Cyan}New feature branch name: ${Grey}"
  read choiceBranchName
  if check_valid_branch $choiceBranchName $ruleAllowExisting; then
    printf "${Grey}"
    git checkout -B $choiceBranchName
    printf "\n${OK}: Feature branch created and switched successfully.\n"
    push_and_set_upstream_if_config_enabled
  else
    printf "\n${Error}: Error creating feature branch at current location.\n"
  fi
}

push_and_set_upstream_if_config_enabled() {
  if [ "$autoPushNewFeatureBranch" = "true" ]; then
    printf "\n${Green}Setting up branch tracking...\n${Grey}"
    git push --set-upstream $originRemoteName $choiceBranchName && {
      printf "\n${OK}: Branch tracking setup successfully.\n"
    } || {
      printf "\n${Error}: Could not push branch to remote.\n"
    }
  fi
}

check_valid_branch() {
  testBranchName=${1}
  ruleAllowExisting=${2} # Options: "MustExist", "MustNotExist", "ConfirmOverwrite", "Any"

  printf "\n${Green}Checking branch name (${Purple} ${testBranchName} ${Green})... ${Grey}"
  {
    # Check that name could be a valid branch name
    printf "${Grey}"
    git check-ref-format --normalize "refs/heads/$testBranchName"
  } && {
    git show-ref --verify --quiet refs/heads/$testBranchName
    # Return code of 0 means branch exists
    branchExists=$?

    case "$ruleAllowExisting" in
      "MustExist")
        if [ "$branchExists" = "0" ]; then
          printf "\n${OK}: Branch exists.\n"
          return 0
        else
          printf "\n${Error}: Branch does not exist.\n"
          return 1
        fi
        ;;
      "MustNotExist")
        if [ "$branchExists" != "0" ]; then
          printf "\n${OK}: Branch does not yet exist.\n"
          return 0
        else
          printf "\n${Error}: Branch already exists.\n"
          return 1
        fi
        ;;
      "ConfirmOverwrite")
        if [ "$branchExists" = "0" ]; then
          printf "\n${Warning}: Branch with name ${Purple}${testBranchName}${Yellow} already exists.\n"
          printf "Confirm overwrite? (Y/n)"
          read -q -n 1 key
          printf "\n"
          case "$key" in
            [yY]) # Overwrite
              printf "\n${Yellow}Overwriting branch... ${Grey}"
              return 0
              ;;
            *)
              return 1
          esac
        else
          printf "\n${OK}: Branch does not exist.\n"
        fi
        ;;
      * )
        printf "\n${OK}: Branch name is valid.\n"
        return 0
        ;;
    esac
  } || {
    printf "\n${Error}: Invalid branch name.\n"
    return 1
  }
}
