#!/usr/bin/env bash
#
export TRUE=true;  export FALSE=false;

# Specify where things should go
export PROJECTS_DIRECTORY="${HOME}/projects";      # The installation path for your new project
export VULCAN_HOME="${PROJECTS_DIRECTORY}/Vulcan"; # The path to the root of your Vulcan installation

export YOUR_ORG="";                                # The GitHub organization name to use
export YOUR_REPO="";                               # The GitHub repo name to use
export YOUR_REPO_BRANCH="";                        # The GitHub repo BRANCH to use
export NEW_PROJECT_NAME="";                        # A name for your new project

export USE_ORIGINAL=${TRUE};
# export USE_ORIGINAL=${FALSE};
if [[ ${USE_ORIGINAL} == ${TRUE} ]]; then

  YOUR_ORG="VulcanJS";
  YOUR_REPO="Vulcan-Starter";
  YOUR_REPO_BRANCH="master";

  NEW_PROJECT_NAME="starter";

else

  YOUR_ORG="FleetingClouds";
  YOUR_REPO="YourPublic";
  YOUR_REPO_BRANCH="server_setup";

  NEW_PROJECT_NAME="yourpublic";

fi;

function killMeteorProcess()
{
  echo -e "${PRETTY} kill meteor processes, if any ...";
  EXISTING_METEOR_PIDS=$(ps aux | grep meteor  | grep -v grep | grep ~/.meteor/packages | awk '{print $2}');
#  echo ">${IFS}<  ${EXISTING_METEOR_PIDS} ";
  for pid in ${EXISTING_METEOR_PIDS}; do
    echo "Kill Meteor process : >> ${pid} <<";
    kill -9 ${pid};
  done;
}

# Create a projects folder and step into it
mkdir -p ${PROJECTS_DIRECTORY};
pushd ${PROJECTS_DIRECTORY};

  # Prepare dependencies
  export PKG="";
  PKG="git";
  dpkg -s ${PKG} >/dev/null ||  sudo apt install -y ${PKG}; # Need git for managing your project's source code.
  PKG="Build-essential";
  dpkg -s ${PKG} >/dev/null ||  sudo apt install -y ${PKG}; # Need C++ build tools for fast bcrypt installation
  PKG="curl";
  dpkg -s ${PKG} >/dev/null ||  sudo apt install -y ${PKG}; # Need curl to get the other stuff.

  # Install 'meteor' IF NECESSARY
  meteor --version || curl https://install.meteor.com/ | sh;

  # Sanity check your Meteor installation
  echo -e "\nMeteor version...";
  meteor --version;
  export METEOR_NODE_VERSION=$(meteor node --version);
  echo -e "Meteor Node version...\n ${METEOR_NODE_VERSION}";

  # Install 'nvm', so as to be able to easily switch NodeJs versions
  curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.5/install.sh | bash;

  # Prepare to use 'nvm' immediately
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

  # Set Meteor version of Node as your default for NodeJS work outside of Meteor
  nvm install ${METEOR_NODE_VERSION};
  nvm alias default ${METEOR_NODE_VERSION};

  # Clone Vulcan core into its own folder and step into it
  git clone git@github.com:VulcanJS/Vulcan.git &>/dev/null;

  # install and pre-cache all of Vulcan's NodeJS dependencies
  export START_LOG="./VulcanStartup.log";
  if [[ -f ${VULCAN_HOME}/${START_LOG} ]]; then
    echo -e "Found start up log '${VULCAN_HOME}/${START_LOG}'. Won't repeat.";
  else
    pushd ${VULCAN_HOME};

        killMeteorProcess;
        meteor npm install;

        echo -e "${PRETTY} Starting VulcanJS in background ...";
        meteor reset;
        nohup meteor npm start > ./${START_LOG} &

        export IDX=2;  # 2 minutes
        while printf "."; ! httping -qc1 http://localhost:3000 && ((IDX-- > 0));
        do
          sleep 6;
        done;

        echo -e "${PRETTY} Started VulcanJS in background!  Now kill it 'cuz we don't need it any more.";
        killMeteorProcess;

    popd;
  fi;
# Clone Vulcan starter kit as your named project
git clone git@github.com:${YOUR_ORG}/${YOUR_REPO}.git ${NEW_PROJECT_NAME};

  # Step in your project folder
  pushd ${NEW_PROJECT_NAME};

    git checkout ${YOUR_REPO_BRANCH};

    # Make sure your app uses the same Meteor release as Vulcan
    cp ${VULCAN_HOME}/.meteor/release ./.meteor;

    # install and pre-cache all of your named app's NodeJS dependencies
    # meteor npm install --save cross-fetch;
    meteor npm install;

    # Make a startup environment variable that tells Meteor to refer
    # to the Vulcan folder for packages that Vulcan supplies
    export PKGDIRVARKEY="METEOR_PACKAGE_DIRS";
    export PKGDIRVARVAL="export METEOR_PACKAGE_DIRS=${VULCAN_HOME}/packages;";
    export PROFILE=${HOME}/.profile;
    grep "${PKGDIRVARKEY}" ${PROFILE} >/dev//null \
      && sed -i "\|${PKGDIRVARKEY}|c${PKGDIRVARVAL}" ${PROFILE} \
      || echo "${PKGDIRVARVAL}" >> ${PROFILE};

    # Confirm the setting was added to ~/.profile
    grep -C 2 "${PKGDIRVARKEY}" ${PROFILE};

    # Run your Vulcan project
    [ -f settings.json ] || cp sample_settings.json settings.json;
    echo -e "Now you can run :

source ${PROFILE};
cd ${PROJECTS_DIRECTORY}/${NEW_PROJECT_NAME};
echo -e \"Starting app with packages from '\${METEOR_PACKAGE_DIRS}'\";
meteor reset;
meteor --port 3000 --settings settings.json;
    ";
  popd;
popd;

