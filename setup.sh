Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White
Grey='\033[0;90m'         # Grey
Reset='\033[0m'           # Text Reset
FullLine="\n${White}------------------------------------------------------"
sourceConfigFilename='./src/addToBashProfile.sh'

printf "${FullLine}"
printf "\n${Green} Remaster Script Easy Setup "
printf "${FullLine}"

printf "\n${Green} This script will: "
printf "\n${Yellow} • ${Green}Copy the source files into ~/bash_calebutils"
printf "\n${Yellow} • ${Green}Add the ${Purple}remaster${Green} script to your bash profile file"
printf "\n${Yellow} • ${Green}Add the ${Purple}fork${Green} script as well"
printf "\n\n"
printf "${Cyan}Would you like to continue? (y/N): ${Grey}"

read -p "" shouldInstall

case "$shouldInstall" in
  [yY][eE][sS]|[yY])
      # Copy files
      printf "\n${FullLine}"
      printf "\n${Green}Copying files..."
      printf "${FullLine}\n${Grey}"

      mkdir ~/bash_calebutils

      # Copy config (ask before overwrite)
      cp -P -n -i src/.bash_calebutils_config.sh ~/bash_calebutils/.bash_calebutils_config.sh && printf "\n${Green}[Config] Copied" || printf "\n${Yellow}[Config] not copied"

      # Copy remaster (no prompt)
      cp -P src/.bash_calebutils_remaster.sh ~/bash_calebutils/.bash_calebutils_remaster.sh && printf "\n${Green}[Remaster] Copied" || printf "\n${Red}[Remaster] not copied"

      # Copy fork (no prompt)
      cp -P src/.bash_calebutils_fork.sh ~/bash_calebutils/.bash_calebutils_fork.sh && printf "\n${Green}[Fork] Copied" || printf "\n${Red}[Fork] not copied"
      printf "\n${Green}DONE"

      # Append to bash profile
      printf "${FullLine}"
      printf "\n${Green} Add Script to Bash Profile"
      printf "${FullLine}"

      printf "\n${Green}The default OSX bash profile filename is ${Purple}.bash_profile"
      printf "\n\n${Cyan}Would you like to use the default file? (Y/n): ${Grey}"
      read -s -n1 shouldUseDefault
      printf "\n"

      case "$shouldUseDefault" in
        [nN])
          printf "\n${Yellow}((${Blue} Custom Bash Profile Filename selection ${Yellow}))${Green}"
          printf "\n${Green}Here are some filenames that might be what you're looking for..."
          printf "\n${White}"
          find ~ -maxdepth 1 -name "*profile*" -exec basename {} \;
          find ~ -maxdepth 1 -name "*bashrc*" -exec basename {} \;
          printf "\n\n${Cyan}Please enter the filename of the bash profile you want to append: ${Grey}"
          read -p "" bashProfileFilename
          ;;
        *)
          bashProfileFilename=".bash_profile"
          ;;
      esac

      printf "\n${Green}Bash Profile Path: ${Cyan}$HOME/$bashProfileFilename ${Green}"
      if [ -f "$HOME/$bashProfileFilename" ]; then
        # Copy files
        printf "\n${FullLine}"
        printf "\n${Green}Install into Bash Profile..."
        printf "${FullLine}\n${Grey}"

        {
          # Make a backup copy of bash profile
          printf "\n${Green}Making a backup copy of ${Purple}$bashProfileFilename ${Green} saved as ${Purple}$bashProfileFilename.bak ${Grey}\n"
          cp -v "$HOME/${bashProfileFilename}" "$HOME/${bashProfileFilename}.bak"
        } && {
          {
            printf "\n\n${Yellow}Overwriting file ${Purple}$HOME/$bashProfileFilename ${Yellow}..."
            # Replace all Caleb Utils with a single temporary line for substitution purposes
            perl -i -p0e 's/### Caleb Utils Start ###.*?### Caleb Utils End ###/## Caleb Utils Replace ##/s' $HOME/$bashProfileFilename
            if grep -q '## Caleb Utils Replace ##' $HOME/$bashProfileFilename; then
              # Copy contents of latest config file into bash profile
              printf "\n\n${Green}Existing config found.  Replacing entry in [${Purple}$HOME/$bashProfileFilename${Green}] from [${Purple}$sourceConfigFilename${Green}] ... "
              sed -i "" -e "/## Caleb Utils Replace ##/{r $sourceConfigFilename" -e "d;}" $HOME/$bashProfileFilename
            else
              printf "\n\n${Green}First time installation detected. Appending to end of file... "
              cat $sourceConfigFilename >> $HOME/$bashProfileFilename
            fi
            printf "${Green}DONE"
          } && {
            # Guide user through config editing process
            printf "\n${FullLine}"
            printf "\n${Green}Edit Config File"
            printf "${FullLine}\n${Grey}"

            printf "\n${Green}You will need to customize the config file to suit your own needs."
            printf "\n\n${Yellow}Press enter to automatically open ${Purple}~/bash_calebutils/.bash_calebutils_config.sh${Yellow}...${Grey}"
            read -p ""
            code ~/bash_calebutils/.bash_calebutils_config.sh && printf "\n${Green}VSCode Editor opened" || printf "\n${Red}VSCode terminal shortcut not installed. Please edit the file manually at this time."
          
            printf "\n${Yellow}Note: Make sure ${Cyan}myCodeDirectory${Yellow} is correct."
            printf "\n\n${Yellow}When you are done editing the config file, press Enter again...${Grey}"
            read -p ""

            # Validate that config and chosen home directory is correct
            printf "\n${Green}Reload bash profile..."
            printf "\n${Green}(${Purple}${HOME}/${bashProfileFilename}${Green})\n${Grey}"
            source $HOME/$bashProfileFilename
            printf "${White}Note: If any errors appeared here, there may be a parsing error with your bash profile."
          }
        } && {
          # Installation Success
          printf "\n\n${Green}Installation success!  You may now use the ✨ ${Purple}remaster${Green} ✨ command in any git repo folder.\n"
        } || {
          # Installation failure
          printf "\n${Red}ERROR: Could not complete installation";
          printf "\n${Yellow}Rolling back to backup ... ${Grey}\n";
          cp -v "$HOME/${bashProfileFilename}.bak" "$HOME/${bashProfileFilename}"
          {
            printf "${Green}DONE";
            printf "\n\n${Green}Rollback successful!"
          } || printf "${Red}ERROR: Could not roll back to backup";
        }


        # List all source files
        # ls -A | cut -f1
      else
        printf "\n${Red}ERROR: Invalid filename"
        return 1
      fi
      printf "\n${Green}"
    ;;
  * )
    ;;
esac

printf "${Reset}"