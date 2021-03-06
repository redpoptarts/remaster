# Git Remaster Script

## Summary

This is a BASH shell script that helps you quickly keep your git branches up to date with upstream.
You add it to your bash profile so that it's always available to you in your terminal by typing `remaster`.

## Requirements

This script was developed for OSX users. It has been tested on Mojave and Catalina.

Full support for **Bash shell**.  
Not designed for **zshell**, but it has been tested and no problems reported yet.

For `remaster` to work in your repo, you must have:

- An **upstream** remote configured _(name is configurable)_
- A **master** branch on that remote
- An **origin** remote _(name is configurable)_
- A **master** branch on that remote _(name is configurable)_

## Dependencies

If you use VSCode, installation will go more smoothly if you enable the `code` Shell Command.

In VSCode, press Command + Shift + P, and begin typing...
```
Shell Command: Install 'code' command in PATH
```
Select this option and press ENTER to install the shortcut.

## Quick Install

Clone this repo down to your machine, and run the following command in terminal from the repo's directory.

```
./setup.sh
```

This script will install the necessary files.

If you have the VSCode `code` command installed, it will automatically open the config file.
If not, you'll have to manually open the file at this point.

![Config file example](https://i.imgur.com/D1ZqTMc.png)

### Config Values
- `myCodeDirectory` : Specify a single folder where most of your GIT repo folders live. Note: This string cannot contain '~'. You should instead use `$HOME`.
- `githubUsername` : Your GitHub Username
- `orgGithub` : Such as `"opentable"`
- `originRemoteName` : Frequently your first name, or `origin`
- `upstreamRemoteName` : Commonly 'upstream'
- `localBranchTrackingOriginMaster` : Commonly 'main', 'master', or 'base'
- `autoPushNewFeatureBranch` : Use "true" or "false". When "true", new branches that are created will automatically push to your remote and configure tracking branches
- `autoOpenVSCodeOnShortcut` : Use "true" or "false". When "true", the script will open the repo in VSCode after the script completes.

If the quick install does not work for you, try the [manual installation](#Manual-Installation).

## Usage

While in any git repo in terminal, type `remaster`.

The purpose of the script is to get your local copy of a repository back in sync with a remote copy, and help you maintain a good git workflow.

### Check for clean working tree

The script will require that you have no uncommitted changes. It will not proceed if that is the case.

### Sync origin/master

Ideally, all that will be needed is origin/master can be fast-forwarded to upstream/master.

If you have been making commits onto your local master branch...

- It will automatically rebase your changes onto upstream/master
- It will complain and remind you that you should be working on a feature branch.
- It will offer to create a feature branch for you at your current location, and restore origin/master back to upstream/master.

### Sync feature branch

This section will apply if you have a branch checked out other than master.

A summary of commits ahead/behind on this branch will be displayed.

If your branch and upstream/master are not pointing to the same commit, then it will ask you how you want to resolve this:

- Rebase the feature branch onto upstream/master
- Begin working on a new branch, which will be created at upstream/master. The commits on your feature branch will be left alone.
- Do nothing. Continue working on your feature branch. The commits on your feature branch will be left alone.

### Auto Yarn/NPM Install

After all operations are complete, the script will check if any changes have occured to the package.json file. If so, it will automatically run `yarn install` or `npm install` for you, depending on which manager is used for the repo.

### Final Status

A short summary of the last 5 commits on your current branch will be displayed. This will include labels for any branch names.

If you have set `autoOpenVSCodeOnShortcut` in your config file, VS Code will automatically open a window for your current directory.

## Logic Diagram

[![Click here to view diagram in Lucid Chart](https://www.lucidchart.com/publicSegments/view/16dff565-a4d5-45d0-a423-acf00c5d50cd/image.png)](https://www.lucidchart.com/documents/view/1563b9bf-d846-4173-9e9b-7b4aefd9afa4)

## Manual Installation

1. Determine which file you want as your bash profile.
   - The default on OSX (Mojave and prior) is `.bash_profile`.
   - If you have a custom shell setup, you may have a different bash profile filename.
2. Make a backup copy of your bash profile
3. Copy the contents of `src/addToBashProfile.sh` into your own bash profile file.
4. Copy the file `./src/bash_calebutils_config.sh` to `~/bash_calebutils/.bash_calebutils_config.sh`
5. Copy the file `./src/bash_calebutils_remaster.sh` to `~/bash_calebutils/.bash_calebutils_remaster.sh`
6. Copy the file `./src/bash_calebutils_fork.sh` to `~/bash_calebutils/.bash_calebutils_fork.sh`
7. Edit the config file to suit your needs
8. Run `source ~/.bash_profile` to load changes to your terminal.
   - If step step causes any errors, the installation has failed. You should restore your bash profile from the backup.

### Fork / Clone Script

After setup, the `fork` script will also be available to you.

The script will:
1) Fork the desired repo if necessary (can be skipped)
2) Clone the repo to your local repos folder (which you configured during setup)
3) Set up your `origin` and `upstream` remotes, and configure your branches
4) `cd` your terminal to the directory so you can get to work immediately

If you would like to fork/clone `orgname/reponame` to `yourgithubusername/reponame`, then use the following command in terminal:
```
fork reponame
```
