function fork() {
  ### Input parameters:
  # $1: repoName

  clear && printf '\e[3J'
  printf "${White}"
  FullLine="\n${White}------------------------------------------------------"
  OK="${Green}✅ OK"
  Warning="${Yellow}⚠️  WARNING"
  Error="${Red}❌ ERROR"

  printf "${FullLine}"
  printf "\n${Green} 🍴 Fork & Clone"
  printf "${FullLine}\n"

  repoName=$1
  appDirectory="${myCodeDirectory}/${repoName}"

  printf "\n"
  printf "${Grey} • The repo ${Yellow}opentable/${Green}${repoName} ${Grey}will be forked into ${Yellow}${githubUsername}/${Green}${repoName}\n\n"
  printf "${Grey} • The repo will be cloned down to your machine into the following directory:\n"
  printf "    ${Cyan}${myCodeDirectory}/${Green}${repoName}\n\n"
  printf "${Grey} • A remote named ${Cyan}${upstreamRemoteName}${Grey} will be setup with a branch named ${Cyan}master \n"
  printf "${Grey} • A remote named ${Cyan}${originRemoteName}${Grey} will be setup with a branch named ${Cyan}$localBranchTrackingOriginMaster \n"

  if [ -d ${appDirectory} ]; then
    printf "\n\n${Purple}====================================================================================="
    printf "\n${Warning}: ${Red} The repo ${Yellow}${repoName}${Red} already exists locally on your machine."
    printf "\n${Red}This operation will overwrite existing changes in this directory!!"
    printf "\n${Purple}=====================================================================================\n\n${Cyan}"
    read -q "shouldForkAndClone? Would you like to fork and clone this repo?(y/N): " 
  else
    printf "\n\n${Green}NOTE: The repo ${Yellow}${repoName}${Green} does not exist locally on your machine.\n\n${Cyan}"
    read -q "shouldForkAndClone? Would you like to fork and clone this repo? (y/N): "
  fi


  case "$shouldForkAndClone" in
    [yY])
      printf "\n\n${Green}Choose a forking method:"
      printf "\n${White}(${Yellow} 0 ${White}) Skip forking, clone only (repo is already forked)"
      printf "\n${White}(${Yellow} 1 ${White}) Open a browser and Fork"
      printf "\n${White}(${Yellow} 2 ${White}) Login to Github in Terminal to Fork ${Cyan}"
      printf "\n\nForking method (1/2): "
      read -s -k "forkingMethod?"
      readytoClone=0

      case "$forkingMethod" in
        0)
          printf "\n\n${Green}Skipping repo forking."
          readytoClone=1
          ;;
        1)
          printf "\n\n${Green}[Command + Double Click] this link to open in a browser:"
          printf "\n${Purple}http://www.github.com/opentable/${repoName}/fork"
          printf "\n    👆                                           👆\n"
          printf "\n\n"
          printf "\n${Blue}When you are done forking this repository in Github, press any key to continue."
          read -s -k
          readytoClone=1
          ;;
        2)
          ### Login to GitHub ####################
          printf "\n\n${Green}GitHub will now attempt to fork your repository."
          printf "\nYou will need:\n"
          printf "\n ${Yellow}○${Green} 2FA (Two Factor Authentication) Code"
          printf "\n ${Yellow}○${Green} GitHub Password\n\n"
          printf "Your password is not stored in memory, it is captured directly via CURL\n\n${Grey}"
          printf "${Cyan}Logging in with Github Username ${Purple}${githubUsername}\n"
          printf "${Cyan}Enter github two-factor authentication code (2FA): ${Grey}"
          read "MFA_CODE?"
          # Ask for password using Curl, then fork
          forkResult=$(curl \
            -u "$githubUsername" \
            -H "X-GitHub-OTP: $MFA_CODE" \
            -s \
            -w "%{http_code}" \
            -X POST "https://api.github.com/repos/opentable/${repoName}/forks" \
            -o /dev/null)
          printf "\n${Green}🍴 Forking repo...\n${Grey}"
          ### End: Login ####################

          case "$forkResult" in
          "401")
            statusColor=$Red
            statusMessage="${Error}: Incorrect password or 2FA code."
            ;;
          "404")
            statusColor=$Red
            statusMessage="${Error}: Authentication error, or repo $repoName doesn't exist."
            ;;
          "200" | "202")
            statusColor=$Green
            statusMessage="${OK}: ${Yellow}${repoName}${Green} forked successfully!"
            readytoClone=1
            ;;
          *)
            statusColor=$Red
            statusMessage="${Error}: Unknown error"
            ;;
          esac

          printf "\n${statusMessage}"
          printf "\n${statusColor}ℹ️  Fork Status Code: $forkResult\n\n"
          ;;
        *)
          printf "\n${Green}🚫 Fork cancelled. No changes made.\n"
          return 1
          ;;
      esac

      if [ "$readytoClone" -eq "1" ]; then
        if [ -d "${appDirectory}" ]; then
          printf "\n${Purple}🗑️  Deleting existing repo directory ${Yellow}$repoName${Purple}... \n\n"
          
          #### Move to system trashcan instead
          # printf "\n${Grey}Clearing trash...\n"
          # cd "${myCodeDirectory}/${repoName}"
          # rm -ri ${repoName}

          # printf "\n${Grey}Moving repo to trash...\n"
          # rm -rf "~/.Trash/${repoName}"

          # mv -fv "${appDirectory}" ~/.Trash && printf "${Warning}: Delete Successful\n" || printf "${Error}: Error deleting repo\n" && return 0
          ####

          rm -rf "${appDirectory}" && printf "${Warning}: Delete Successful\n" || printf "${Error}: "

          cd ${myCodeDirectory}
        fi

        printf "\n${Green}🛸 Cloning repo... (${Purple}git@github.com:$githubUsername/${repoName}.git${Green}) \n"

        {
          printf "${Grey}"
          git clone -v "git@github.com:$githubUsername/${repoName}.git" "${appDirectory}" --origin $originRemoteName
        } && {
          printf "\n${OK}: Clone successful!\n"
        } || {
          printf "\n${Error}: Clone failed. Could not clone repo to [${appDirectory}]. \n\n"
          return 1
        }

        cd $appDirectory

        printf "\n${Green}📡 Configuring remotes...  (${Purple}$originRemoteName${Green})(${Purple}$upstreamRemoteName${Green})\n${Grey}"
        git remote add $upstreamRemoteName "git@github.com:opentable/${repoName}.git"
        git remote -v show

        printf "\n${Green}🌵 Configuring local branches...  (${Purple}$localBranchTrackingOriginMaster${Green})\n${Grey}"
        if [ $localBranchTrackingOriginMaster != "master" ]; then
          git branch -m master "$localBranchTrackingOriginMaster"
        fi
        git branch -u $originRemoteName/master

        printf "\n${Green}⬇️  Getting latest changes...\n${Grey}"
        git fetch --all

        printf "\n${Green}📂 Changing directory to: ${Cyan}${appDirectory}\n\n${Reset}"
        return 0
      else
        printf "\n${Error}: Could not fork repo. Status code ($forkResult)\n\n"
      fi
      ;;
  esac
  return 1
}
