# Background
Please check this issue for details as to why these scripts exists: 
https://github.com/firebase/firebase-functions/issues/607

# Usage
The scripts are located in `packages/api/functions/scripts`.
To use them, simply call them and provide them the root of the functions directory.
For example from `packages/api` directory: `scripts/predeploy.sh ./functions`.

You also need to edit both `predeploy.sh` and `postdeploy.sh` to fill in your shared workspaces and their locations, else it will not work.

Please also check `packages/api/firebase.json` to see how these work with firebase `predeploy` and `postdeploy`.

**REMEMBER** that you _need_ to run yarn after the predeploy and postdeploy script, else the workspace packages will not be installed/removed correctly.

# How it works
The **predeploy** script basically involves the following steps:
* Fetching the packed files for the shared workspaces using `npm-packlist`.
* Copy the the packed files into a _dist_ directory under the correct scope and package name (example `dist/@my-org/shared`). Firebase will use this to install during deployment.
* Modify package.json to point the package to the copied directory (example  `'@my-org/shared': 'file:dist/@my-org/shared').

The **postdeploy** script:
* Check if a package.json backup exists, if not exit.
* Remove the dist files that were created from the _predeploy_ script.
* Restore the package.json from backup.

One negative side to this is that postdeploy does **not** run if the deployment fails, which means the package.json is not restored.
I have an idea to turn this into a full tool which will handle deployment failures automatically, but for now this works.
