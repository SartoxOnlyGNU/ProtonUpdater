#!/usr/bin/env bash

baseuri="https://github.com/GloriousEggroll/proton-ge-custom/releases/download"
latesturi="https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest"

# These should NOT be changed in the code directly.
parameter="${1}"
restartSteam="${2}"
autoInstall="${3}"

installComplete=false

# Destination folder for the Proton installations.
dstpath="$HOME/.steam/root/compatibilitytools.d"

PrintReleases()
{
  echo "----------Description-----------"
  echo "Install, by default, the latest Proton GE build available."
  echo "Or, if specified, install one or multiple specific Proton GE build(s)."
  echo ""
  echo "------------Options------------"
  echo "<script> [-l|VersionName] [RestartSteam] [AutoInstall]"
  echo "-l lists this message and, at the bottom, the most recent 30 Proton GE releases. VersionName is the version of a specific Proton GE build to install."
  echo ""
  echo "RestartSteam can be at :"
  echo " - 0 : Don't restart Steam after installing Proton GE."
  echo " - 1 : Restart Steam after installing Proton GE."
  echo " - 2 : Get a prompt asking if you want to restart Steam after each installation."
  echo ""
  echo "AutoInstall can be :"
  echo " - true : Skip the installation prompt and install the latest Proton GE build (if not installed), or any forced Proton GE build(s)."
  echo " - false : Display a confirmation prompt when installing a Proton GE build."
  echo ""
  echo "------------WARNING------------"
  echo "Subversions of Proton GE builds may be installed as their main version. Support for them might come in the future as time goes by."
  echo ""
  echo "------------Releases------------"
  curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases | grep -H "tag_name" | cut -d \" -f4
  echo "--------------------------------"
}

InstallProtonGE()
{
  rsp="$(curl -sI "$url" | head -1)"
  echo "$rsp" | grep -q 302 || {
    echo "$rsp"
    exit 1
  }

  [ -d "$dstpath" ] || {
    mkdir "$dstpath"
    echo [Info] Created "$dstpath"
  }

  curl -sL "$url" | tar xfzv - -C "$dstpath"
  installComplete=true
}

DeletePrompt()
{
    read -r -p "Do you want to delete installed versions? <y/N> " prompt
    if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]; then
        DeleteProtonCheck
    else
        RestartSteamCheck
    fi
}

DeleteProtonCheck()
{
    echo "Installed runners :"
    installed_versions=($(ls -d "$dstpath"/*/))
    for((i=0;i<${#installed_versions[@]};i++)); do
        inumber=$(("$i" + 1))
        folder=$(echo "${installed_versions[i]}" | rev | cut -d/ -f2 | rev)
        echo "$inumber. $folder"
    done
    echo ""
    echo -n "Please select a version to remove : [1-${#installed_versions[@]}]:"
    read -ra option_remove
    
    case "$option_remove" in
        [1-9])
        if (( $option_remove<= ${#installed_versions[@]} )); then
            remove_option=${installed_versions[$option_remove -1]}
            echo "removing $remove_option"
            DeleteProtonPrompt
        else
            echo "That is not a valid option"
        fi
        ;;
        *)
            echo "Not a valid option" 
        ;;
    esac
}

DeleteProtonPrompt()
{
    read -r -p "Do you really want to permanently delete this version? <y/N> " prompt
    if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]; then
      DeleteProton
    else
      echo "Operation canceled"
      DeletePrompt
    fi
}

DeleteProton()
{
    rm -rf $remove_option
    echo "removed $remove_option"
    installComplete=true
    DeletePrompt
}

RestartSteam()
{
  if [ "$( pgrep steam )" != "" ]; then
    echo "Restarting Steam"
    pkill -TERM steam #restarting Steam
    sleep 5s
    nohup steam </dev/null &>/dev/null &
  fi
}

RestartSteamCheck()
{
  if [ "$( pgrep steam )" != "" ] && [ "$installComplete" = true ]; then
    if [ "$restartSteam" == "2" ]; then
      read -r -p "Do you want to restart Steam? <y/N> " prompt
      if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]; then
        RestartSteam
      else
        exit 2
      fi
    elif [ "$restartSteam" == "0" ]; then
      exit 0
    fi
    RestartSteam
  fi
}

InstallationPrompt()
{
  if [ "$autoInstall" == "true" ]; then
    if [ ! -d "$dstpath/Proton-$version" ]; then
      InstallProtonGE
    fi
  else
    read -r -p "Do you want to download and (re)install this release? <y/N> " prompt
    if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]; then
      InstallProtonGE
      DeletePrompt
    else
      echo "Operation cancelled."
      DeletePrompt
    fi
  fi
}

if [ -z "$restartSteam" ]; then
	restartSteam=2
fi

if [ -z "$autoInstall" ]; then
	autoInstall=false
fi

if [ -z "$parameter" ]; then
  version="$(curl -s $latesturi | grep -E -m1 "tag_name" | cut -d \" -f4)"
  
  # TODO : Fix parsing maybe?
  #url=$(curl -s $latesturi | grep -E -m1 "browser_download_url.*Proton" | cut -d \" -f4) 
  url="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${version}/Proton-${version}.tar.gz"

  if [ -d "$dstpath/Proton-$version" ]; then
    echo "You already have the latest version installed of Proton GE! ($version)"
  else
    echo "The latest version of Proton GE ($version) is not installed."
  fi
elif [ "$parameter" == "-l" ]; then
  PrintReleases
else
  url=$baseuri/"$parameter"/Proton-"$parameter".tar.gz

  if [ -d "$dstpath"/Proton-"$parameter" ]; then
    echo "You already have this version installed! ($parameter)"
  else
    echo "The version of Proton GE selected ($parameter) is not installed."
  fi
fi

if [ ! "$parameter" == "-l" ]; then
  InstallationPrompt
fi
