
// Source: https://stackoverflow.com/a/22185855/9084561

const fs = require("fs")
const path = require("path")

/**
 * Look ma, it's cp -R.
 * @param {string} src  The path to the thing to copy.
 * @param {string} dest The path to the new copy.
 */
var copyRecursiveSync = function(src, dest) {
  var exists = fs.existsSync(src);
  var stats = exists && fs.statSync(src);
  var isDirectory = exists && stats.isDirectory();
  if (isDirectory) {
    fs.mkdirSync(dest, { recursive: true });
    fs.readdirSync(src).forEach(function(childItemName) {
      copyRecursiveSync(path.join(src, childItemName),
                        path.join(dest, childItemName));
    });
  } else {
    fs.copyFileSync(src, dest, fs.constants.COPYFILE_FICLONE);
  }
};

// Define sources and destinations for both themes named "casper" and "source".
let sourcePath = ("/var/lib/ghost/content.orig/themes/");
let destinationPath = ("/var/lib/ghost/content/themes");

// Wrap the function in a try/catch block to handle any errors.
try {
  copyRecursiveSync(sourcePath, destinationPath)
  console.log("Copy successful!");
}
catch (error) {
  console.error("Error copying files: ", error);
}

// Run Ghost from the current version.
require("./index.js");
