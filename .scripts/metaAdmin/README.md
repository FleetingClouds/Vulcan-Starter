# Multi-site VulcanJS .

## Parameters for the included scripts

This directory contains two folders to copy to your ${HOME} directory ...

    .vulcan/
    └── index.json

... and ...

    .ssh/
    └── deploy_vault
        ├── localhost
        │   ├── deploy_user
        │   │   ├── example.id_rsa
        │   │   └── example.id_rsa.pub
        │   ├── dh
        │   │   └── example.dhparams_4096.pem
        │   ├── example.letsencrypt.tar.gz
        │   └── example.secrets.json
        └── yoursite.yourpublic.work
            ├── deploy_user
            │   ├── example.id_rsa
            │   └── example.id_rsa.pub
            ├── dh
            │   └── example.dhparams_4096.pem
            ├── example.letsencrypt.tar.gz
            └── example.secrets.json

The file ```.vulcan/index.json``` contains public knowledge parameters to be used by the continuous deployment scripts.  Some of those parameters are pointers to secret parameters files kept in ```.ssh/deploy_vault```.

So, executing ```./USE_ME_TO_GET_STARTED.sh yoursite.yourpublic.work``` will cause the scripts to access the ```.vulcan/index.json``` file in the section ```.virtual_hosts.'yoursite.yourpublic.work'.DEPLOY_VAULT``` in order to find the relevant secrets for that target virtual host.

Likewise, reading ```./package.json``` --> ```.name``` the scripts will be directed to the section ```.applications.yourpublic```.

In this way, a project manager for multiple applications on multiple remote hosts can easily manage all their public and private information.
