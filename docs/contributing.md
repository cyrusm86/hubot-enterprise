# How to contribute

## Developer workflow

To start coding new features or fixes to
`Hubot Enterprise` follow these steps:

* Get a slack token for testing as described [here](https://github.com/eedevops/hubot-enterprise/wiki/bootstrap#tokens-for-testing). 
* If you are not a member of the eedevops organization fork this repository.
* Clone the repository in your local environment.
* _Assuming_ that you have `node` and `npm` installed in your system, install `hubot-enterprise` 
  dependencies locally. 
  ```bash
  cd hubot-enterprise
  npm install
  ```
  > You must have a `./node_modules` directory in your project after issuing this command.
  
* _Assuming_ that you have `docker` and `docker compose` installed, run the following 
command:

  ```bash
  # This will build the docker image the first time around.
  docker-compose up 
  ```
  
  If you are in an environment with a corporate proxy, use the following command instead 
  of the above:
  
  ```bash
  # The dc.proxy.yml extends the build and run processes to include 
  # environment variables for your proxies. 
  docker-compose -f docker-compose.yml -f dc.proxy.yml up   
  ```
  
  > Using docker compose allows us to mount your current copy of the repo
  > as a volume in the docker container (under `/bot/node_modules/hubot-enterprise`).
  
  You should then see at the end an output similar to this:
  
  ```bash
  he_1  | running installer
  he_1  | nothing to install...
  he_1  | npm info it worked if it ends with ok
  he_1  | npm info using npm@2.15.9
  he_1  | npm info using node@v4.6.0
  he_1  | npm info preinstall bot@0.0.0
  he_1  | npm info package.json hubot-scripts@2.17.2 No license field.
  he_1  | npm info package.json querystring@0.2.0 querystring is also the name of a node core module.
  he_1  | npm info package.json querystring@0.2.0 No license field.
  he_1  | npm info prepublish hubot-enterprise@0.2.1
  he_1  | npm info already installed hubot-enterprise@0.2.1
  he_1  | npm info build /bot
  he_1  | npm info linkStuff bot@0.0.0
  he_1  | npm info install bot@0.0.0
  he_1  | npm info postinstall bot@0.0.0
  he_1  | npm info prepublish bot@0.0.0
  he_1  | npm info ok 
  he_1  | [Thu Oct 13 2016 14:44:46 GMT+0000 (UTC)] DEBUG Loading adapter slack
  he_1  | [Thu Oct 13 2016 14:44:47 GMT+0000 (UTC)] INFO Logged in as rqcbot of slacker
  he_1  | [Thu Oct 13 2016 14:44:48 GMT+0000 (UTC)] INFO Slack client now connected
  he_1  | [Thu Oct 13 2016 14:44:48 GMT+0000 (UTC)] DEBUG Loading scripts from /bot/scripts
  he_1  | [Thu Oct 13 2016 14:44:48 GMT+0000 (UTC)] DEBUG Loading scripts from /bot/src/scripts
  he_1  | [Thu Oct 13 2016 14:44:48 GMT+0000 (UTC)] DEBUG Loading external-scripts from npm packages
  he_1  | [Thu Oct 13 2016 14:44:51 GMT+0000 (UTC)] DEBUG Loading scripts from /bot/enterprise_scripts
  he_1  | [Thu Oct 13 2016 14:44:51 GMT+0000 (UTC)] DEBUG Parsing help for /bot/enterprise_scripts/example.coffee
  he_1  | [Thu Oct 13 2016 14:44:51 GMT+0000 (UTC)] DEBUG Parsing help for /bot/node_modules/hubot-enterprise/src/0_bootstrap.coffee
  he_1  | [Thu Oct 13 2016 14:44:51 GMT+0000 (UTC)] DEBUG HE registering call:
  he_1  |         robot.respond /admin archive channel[ ]?(.*)?$/i
  he_1  | [Thu Oct 13 2016 14:44:51 GMT+0000 (UTC)] DEBUG HE registering call:
  he_1  |         robot.respond /admin archive older ([0-9]+)([dDhHmMsS]) ?(.*)$/i
  he_1  | [Thu Oct 13 2016 14:44:51 GMT+0000 (UTC)] DEBUG Parsing help for /bot/node_modules/hubot-enterprise/src/admin.coffee
  he_1  | [Thu Oct 13 2016 14:44:51 GMT+0000 (UTC)] DEBUG Parsing help for /bot/node_modules/hubot-diagnostics/src/diagnostics.coffee
  he_1  | [Thu Oct 13 2016 14:44:51 GMT+0000 (UTC)] DEBUG Parsing help for /bot/node_modules/hubot-help/src/help.coffee
  he_1  | [Thu Oct 13 2016 14:44:51 GMT+0000 (UTC)] INFO hubot-redis-brain: Using default redis on localhost:6379
  he_1  | [Thu Oct 13 2016 14:44:51 GMT+0000 (UTC)] DEBUG Parsing help for /bot/node_modules/hubot-redis-brain/src/redis-brain.coffee
  ```

* When you make changes in your local copy of the `hubot-enteprise` repo
  you should restart the container:
  
  ```bash
    # press CTRL-C keys in your terminal
    docker-compose up
  ```
  > You should be able to see your changes.

## Write tests and run test suite

As a contributor to `hubot-enterprise` you must provide appropriate tests
for your new or changed functionality. You must add these under `/test` directory.

Also, you should make sure that your work did not affect other modules or
that it invalidated existing tests. Therefore, you should run the entire test
suite manually in your environment before submitting a pull request:

```bash
npm test
```

You should see an output like this if all tests passed:

```bash
  ...

    ✓ extra passed as string (backward compatibility)- call with suffix
    ✓ extra passed as string (backward compatibility)- call without suffix


  49 passing (786ms)
```

If there was an error you could see a message like this:
 
```bash
  ...
  
  40 passing (4s)
  6 failing

  ...
```


You should also see a report under `./test/xunit.xml` file.

## Run linter

Finally, you should make sure that your code follows the coding standards and 
best practices of our project by running its linter:

```bash
# Run coffeescript linter
npm run coffeelint 
# Run javascript linter
npm run jslint
```

Output files will be in the root of your project in `js-lint.xml` and `coffee-lint.xml`.
