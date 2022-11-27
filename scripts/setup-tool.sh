#!/usr/bin/env bash

# load this with
ID=6e27d6adfc51a167384608b16d136a29
REV=287d4acbc35f0dfe7d29513cb53d20af3f283aa0
# eval "$(curl -s -o- https://gist.githubusercontent.com/JeanMGirard/$ID/raw/$REV/install-tools.sh)"

INSTALLED_PACKAGES=""

touch ~/.bashrc ~/.zshrc

SUDO_CMD=""

function managed-pkg {
  if [[ "$INSTALLED_PACKAGES" != *":$1:"* ]]; then
    INSTALLED_PACKAGES="$INSTALLED_PACKAGES:$1:";
  fi;
}
function log-install {
	echo "Installing: $1" && sleep 1;
}
function log-installed {
	managed-pkg "$1"
	echo " \"$1\" installed";
}
function log-skipped {
	managed-pkg "$1"
	echo " \"$1\" already installed";
}

function setup::clear-installed {
	INSTALLED_PACKAGES=""
}
function setup::list-installed {
	echo "$INSTALLED_PACKAGES" | sed 's/:/ /g'
}
function setup::register-alias {
  touch ~/.aliases
  LN="alias $1=";
  alias $1="$2";
  sed -i "/^$LN/d" ~/.aliases;
  echo "$LN'$2'" >> ~/.aliases;
}

function setup::register-repo {
  unset CONTINUE CAN_FAIL NAME URL REPO_TYPE

  while test $# -gt 0; do
    case "$1" in
      -y | --yes) CONTINUE="yes" ;;
      -t | --try) CAN_FAIL="on" ;;
      -* | --*)   echo "bad option $1" ;;
      *)
        if   [[ -z "$NAME" ]];  then NAME="$1";
        elif [[ -z "$URL" ]];   then URL="$1";
        elif [[ -z "$REPO_TYPE" ]]; then
          REPO_TYPE="$NAME"
          NAME="$URL";
          URL="$1";
        else
          echo "too many arguments $1";
          return;
        fi
        ;;
    esac;
    shift;
  done

  if [[ -z "$URL" ]]; then
    echo "missing values";
    return;
  elif [[ -z "$REPO_TYPE" ]]; then
    if   [[ "$URL" == *"apt"* ]]; then REPO_TYPE="apt";
    elif [[ "$URL" == *"yum"* ]]; then REPO_TYPE="yum";
    elif command -v apt &> /dev/null;   then REPO_TYPE="apt";
    elif command -v yum &> /dev/null;   then REPO_TYPE="yum";
    fi
  fi


  if [[ -z "$REPO_TYPE" ]]; then
    echo "unable to resolve the repo type"
    return;
  fi


  if [[ "$REPO_TYPE" == "apt" ]]; then
    if ! command -v apt &> /dev/null; then
      return;
    fi;
    CONTENT="deb [trusted=yes] $URL /"
    TO_FILE="/etc/apt/sources.list.d/$NAME.list"
    EXTRA_CMD="$SUDO_CMD apt update"

  elif [[ "$REPO_TYPE" == "yum" ]]; then
    if ! command -v yum &> /dev/null; then
      return;
    fi;
    CONTENT=$"[$NAME]\nname=$NAME Repo\nbaseurl=$URL\nenabled=1\ngpgcheck=0"
    TO_FILE="/etc/yum.repos.d/$NAME.repo"
  fi



  if [[ "$CONTINUE" != "yes" ]]; then
    echo -e "\nwill write to '$TO_FILE'\n----- ";
    echo -e "$CONTENT\n-----\n";
    return;
  fi

  echo -e "$CONTENT" | $SUDO_CMD tee "$TO_FILE"
  $EXTRA_CMD
}

function setup::cmd_install() {
  if   command -v apt-get &> /dev/null; then echo "apt-get install -y"
  elif command -v yum &> /dev/null; then echo "yum install -y"
  elif command -v apk &> /dev/null; then echo "apk add --no-cache"
  elif command -v zypper &> /dev/null; then echo "zypper install -y"
  elif command -v pacman &> /dev/null; then echo "pacman -Syu"
  elif command -v dnf &> /dev/null; then echo "dnf install -y"
  fi
}
function setup::cmd_update() {
  if   command -v apt-get &> /dev/null; then echo "apt-get update"
  elif command -v yum &> /dev/null; then echo "yum update"
  elif command -v apk &> /dev/null; then echo "apk update"
  fi
}
function setup::cmd_upgrade() {
  if   command -v apt-get &> /dev/null; then echo "apt-get upgrade"
  elif command -v yum &> /dev/null; then echo "yum upgrade"
  elif command -v apk &> /dev/null; then echo "apk upgrade --no-cache"
  fi
}

function wrap_cmd {
	local TEST="" PKG="" CMD=""

  while [[ $# -gt 0 ]]; do case "$1" in
    -t | --test) TEST="$2"; shift; ;;
   	*) if [[ -z "$PKG" ]]; then PKG="$1"; else CMD="$CMD $1"; fi
  esac; shift; done;

  if [[ "$(setup::is-installed --test "${TEST:-$PKG}" $PKG)" == "no" ]]; then
  	# echo "setup::is-installed --test \"${TEST:-$PKG}\" $PKG"
  	log-install $PKG;
  	eval "$CMD $PKG"
  	log-installed $PKG
  else
    log-skipped $PKG;
  fi
}

function setup::install-repo {
	if [[ "$(setup::is-installed $@)" == "no" ]]; then
		log-install $@;
		$SUDO_CMD `setup::cmd_install` "$1";
		log-installed $@;
	else
		log-skipped $@;
	fi
}
function setup::install-pip {
	# wrap_cmd $@ "sudo -H pip install";
	wrap_cmd $@ "pip install";
}

# setup::install-npm @nestjs/cli --test "nest"

function setup::install-npm {
	wrap_cmd $@ "npm i -g";
}
function setup::install-go {
	wrap_cmd $@ "go install";
}
function setup::install-rust {
	wrap_cmd $@ "cargo install -f";
}

function setup::is-installed {
	TEST=; CMD="";
	while [[ $# -gt 0 ]]; do case "$1" in
  	-t | --test) TEST="$2"; shift; ;;
 		*) CMD="$1";
  esac; shift; done;


	if ! command -v ${TEST:-$CMD} &> /dev/null; then
		printf "no";
  else
  	printf "yes";
  fi
}
function setup::install-pkgs {
  # echo "Installing packages: $@" && sleep 2;
  for pkg in $@; do setup::install-pkg $pkg; done;
}
function setup::install-pkg {
	local TEST="" PKG="" EVAL="";

  while [[ $# -gt 0 ]]; do case "$1" in
    -t | --test) TEST="$2"; shift; ;;
   	*) 	if [[ -z "$PKG" ]]; then PKG="$1";
   			else EVAL="$EVAL $1"; fi;
  esac; shift; done;

  if ! command -v "${TEST:-$PKG}" &> /dev/null; then
  	log-install "$PKG";

    if [[ -z "$EVAL" ]]; then
    	setup::install-repo "$PKG";
    else
      # echo -e " TEST: $TEST \n PKG: $PKG \n EVAL: $EVAL $@"

    	if [[ "$EVAL" == "/"* ]]; then source $EVAL;
    	else eval "$EVAL"; fi;
		fi
    log-installed "$PKG";
  else log-skipped "$PKG"; fi;
}

