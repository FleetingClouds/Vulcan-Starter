# Specify where things should go
export NEW_PROJECT_NAME="VStart";                # a name for your new project
export PROJECTS_DIRECTORY="${HOME}/projects";      # the installation path for your new project
export VULCAN_HOME="${PROJECTS_DIRECTORY}/Vulcan"; # the path to the root of your Vulcan installation

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
  pushd ${VULCAN_HOME};

    meteor npm install;

  popd;

# Clone Vulcan starter kit as your named project
git clone git@github.com:VulcanJS/Vulcan-Starter.git ${NEW_PROJECT_NAME};

  # Step in your project folder
  pushd ${NEW_PROJECT_NAME};

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
       meteor --port 3000 --settings settings.json;
    ";
  popd;
popd;

