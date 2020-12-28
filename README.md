# Background
Please check this issue for details as to why these scripts exists: 
https://github.com/firebase/firebase-functions/issues/607

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