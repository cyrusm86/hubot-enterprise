import groovy.json.*

def get_version ( fname ) {
    def jsonText = readFile(fname)
    def json = new JsonSlurper().parseText(jsonText)
    return json.version
}

def wraps(body) {
    wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'XTerm', 'defaultFg': 1, 'defaultBg': 2]) {
        wrap([$class: 'TimestamperBuildWrapper']) {
            body()
        }
    }
}

def get_tag_version (){
    sh "git describe --tags `git rev-list --tags --max-count=1` | sed s/^v//g | sed s/-.*//g > ver.txt"
    return readFile('ver.txt').trim()
}

def get_tags_diff () {
    try {
        sh "git describe --tags"
        sh 'git log --no-merges $(git describe --tags `git rev-list --tags --max-count=1`)..HEAD --pretty=\'tformat:- %s\' > changes.txt'
    } catch (e) {
        sh 'git log --no-merges --pretty=\'tformat:- %s\' > changes.txt'
    }
    return 'changes.txt'
}

def check_pr ( env_vars ) {
    return env_vars.CHANGE_TARGET ? true : false
}

def guess_github_settings () {
    sh 'git remote -v | grep origin | head -1 | awk \'{print $2}\' | sed \'s/git@//g;s/\\.git//g\' > guess'
    def str = readFile('guess').trim().split(':')
    def ret = [api: '', project: str[1], cred: '']
    if (str[0] == 'github.com')
    {
        ret.api = 'https://api.'+str[0]
        ret.cred = 'github-token'
    } else {
        ret.api =  'https://'+str[0]+'/api/v3'
        ret.cred = 'github-enterprise-token'
    }
    println 'Project: '+ret.api+' '+ret.cred+' '+ret.project
    return ret
}

def create_version_json (url, path, auth, version_name, version_tag, prerelease, changes) {
    echo 'creating new github version'
    def obj = [tag_name: version_tag, name: version_name, body: changes, draft: false, prerelease: prerelease]
    def json = JsonOutput.toJson(obj)
    println "Sending to github:\n${json}"
    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: auth, passwordVariable: 'PW', usernameVariable: 'UN']]) {
        sh "curl -H \'Authorization: token ${env.PW}\' --request POST --data \'${json}\' ${url}/repos/${path}/releases > out"
    }
    def resFile = readFile('out').trim()
    def res = new JsonSlurper().parseText(resFile)
    echo "result:\n"+resFile
}

def changeURL

node {
    wraps {
        try{
            stage 'Clean workspace'
            deleteDir()
            sh 'ls -lah'
            stage 'Checkout source'
            checkout scm
            def version = get_version ('package.json')
            echo "version ${version}"
            changeURL = check_pr(env) ? "\nChange URL: ${env.CHANGE_URL}" : "";
            sh 'env'
            stage 'build'
            sh 'npm install'
            stage 'linter'
            sh 'npm run coffeelint'
            sh 'npm run jslint'
            step([$class: 'WarningsPublisher', canComputeNew: false, canResolveRelativePaths: false, defaultEncoding: '', excludePattern: '',
                    healthy: '', includePattern: '', messagesPattern: '', parserConfigurations: [[parserName: 'JSLint', pattern: '*lint.xml']], unHealthy: ''])
            stage 'test'
            sh 'npm test || true'
            step([$class: 'JUnitResultArchiver', testResults: 'test/xunit.xml'])
            if (currentBuild.result != 'UNSTABLE')
            {
                def tag_version = get_tag_version()
                echo "latest tag version: "+tag_version
                echo 'versions: ['+version +'] ['+tag_version+']'
                if (!check_pr(env) && (version != tag_version) && (env.BRANCH_NAME == 'master'))
                {
                    stage 'package'
                    def changes = get_tags_diff()
                    sh "git tag v${version}" // -F ${changes}"
                    sshagent(['github-ssh']) { sh "git -c core.askpass=true push --tags" }
                    def gconf = guess_github_settings()
                    create_version_json (gconf.api, gconf.project, gconf.cred, "${version}", "v${version}", true, readFile(changes))
                    echo 'done!'
                } else if (check_pr(env)) {
                    echo 'it\'s a pull request, not tagging'
                } else if (env.BRANCH_NAME != 'master') {
                    echo 'not creating release for non master branches'
                } else {
                    echo "version is the same, not tagging"
                }
                slackSend color: 'good', message: "Build done: ${env.JOB_NAME} ${env.BUILD_NUMBER}\n${env.BUILD_URL}${changeURL}"
            } else {
                slackSend color: 'warning', message: "Unit tests failed: ${env.JOB_NAME} ${env.BUILD_NUMBER}\n${env.BUILD_URL}${changeURL}"
            }
            step([$class: 'GitHubCommitStatusSetter', statusResultSource: [$class: 'ConditionalStatusResultSource', results: []]])
        } catch (e) {
            echo "Exception: ${e}"
            slackSend color: 'danger', message: "Job failed: ${env.JOB_NAME} ${env.BUILD_NUMBER}\n${env.BUILD_URL}${changeURL}"
            currentBuild.result='FAILED'
            step([$class: 'GitHubCommitStatusSetter', statusResultSource: [$class: 'ConditionalStatusResultSource', results: []]])
            error "${e}"
        }
	echo "status: [${currentBuild.result}]"
    }
}
