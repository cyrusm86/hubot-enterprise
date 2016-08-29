/*
 Copyright 2016 Hewlett-Packard Development Company, L.P.

 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 of the Software, and to permit persons to whom the Software is furnished to do
 so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
*/

/*
  script to install integration from disk and params
*/

var fs = require('fs');
var path = require('path');
var url = require('url');
var child_process = require('child_process');
var HUBOT_PREFIX = 'hubot-';
var workdir = process.cwd();

/**
 * Check file exists
 *
 * @param {string} file File path
 *
 * @return {boolean} If file exists or not
 */
function checkFile(file){
  try{
    return fs.statSync(file);
  }catch (e){
    return false;
  }
}

/**
 * Install npm packages
 *
 * @param {(string|Array.)} pkg Package(s) to install
 * @param {Object} opts Options for installation
 * @param {boolean} opts.sudo Install with sudo
 * @param {boolean} opts.save Install with --save
 * @param {boolean} opts.global Install with --global
 * @param {string} opts.cwd Location to run install in
 */
function npm_install(pkg, opts){
  ops = opts||{};
  pkg = pkg.join(' ');
  var command = (opts.sudo ? 'sudo ' : '')+'npm install '+(opts.save ? '--save ' : '')+(opts.global ? '-g ' : '')+pkg;
  console.log('Running: '+command);
  child_process.execSync(command, {stdio:[0, 1, 2], cwd: ops.cwd||process.cwd()});
  return true;
}

/**
 * Add packages to external-scripts.json
 *
 * @param {Array} pkgs Packages to add
 * @param {string} install_dir Directory which external-script.json located
 */
function append_external(pkgs, install_dir){
  var external = install_dir+'/external-scripts.json';
  var existing = JSON.parse(fs.readFileSync(external).toString());
  pkgs = pkgs.map(function(pkg){
  // adding names, cleaning names to get ONLY the package name
  // removing urls, versions, organizations etc...
  return path.basename(url.parse(pkg).pathname).replace(/@.*/, '');
  }).forEach(function(pkg){
	//writing only if package name not already exists in external-script.json
    if (existing.indexOf(pkg)<0)
      existing.push(pkg);
  });
  fs.writeFileSync(external, JSON.stringify(existing, null, ' '));
}

/**
 * Install integrations
 *
 * @param {string} install_dir Hubot directory
 * @param {{string|Array.}} remote_packages List of packages to install from npm
 *   Any npm recognized package type (name, name@version, github_org/repo etc..)
 * @param {string} scripts_dir location of local packages to install, can be flat
     or directory with bumber of integrations prefixed with hubot-
 */
function install_integrations(install_dir, remote_packages, scripts_dir){
  console.log('running installer');
  // converting remote_packages into an array
  if (remote_packages && !(remote_packages instanceof Array))
    remote_packages = remote_packages.split(' ');
  var contents = [];
  var names = [];
  
  //check if path exists, it might not be mounted
  if (checkFile(scripts_dir))
  {
	// check if path is not flat project
	// if not: assume that contains number of packages
    if (!checkFile(scripts_dir+'/package.json'))
    {
	  // take only packages prefixed with hubot-
      contents = fs.readdirSync(scripts_dir)
      .filter(function(folder){ return folder.startsWith(HUBOT_PREFIX); })
      .map(function(dir){ return scripts_dir+'/'+dir; });
	  // add names to contents as is
      names = contents;
    } else {
	  // install the script dir
      contents = [scripts_dir];
	  // the name is the package name from package.json
      names = [JSON.parse(fs.readFileSync(scripts_dir+
	    '/package.json').toString()).name];
    }
  }
  
  // add remote packages, if any...
  if (remote_packages.length > 0)
  {
    contents = contents.concat(remote_packages);
    names = names.concat(remote_packages);
  }
  // return if nothing to install
  if (contents.length === 0)
    return void console.log('nothing to install...');
  console.log('adding:\n'+contents.join('\n'));
  // npm install packages
  if (!npm_install(contents, {save: true, cwd: install_dir}))
    return 1;
  // add names to external-script.json
  if (append_external(names, install_dir))
    return 1;
}

/**
 * Show help
 */
function help(){
  console.log('Usage: node '+path.basename(__filename)+' <scripts_dir> <npms list> <install_dir>');
}

/**
 * main function
 */
function main(){
  if (process.argv.length != 5)
  {
    help();
    return 1;
  }
  install_integrations(process.argv[4].trim(), process.argv[3].trim(),
    process.argv[2].trim());
}

//run main function, exit with function exit code
process.exit(main());
