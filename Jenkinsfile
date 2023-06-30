pipeline {
	agent {
		node {
			label "encyclopedia-project-agent"
		}
	}
	triggers {
		// this means once per minute. Change it later to once per 5 mins, or more
		pollSCM "* * * * *"
	}
	stages {
		stage("Build") {
			steps {
				sh "npm install"
			}
		}
		stage("Test") {
			steps {
				sh "npm test"
				// add a JMeter test ?
			}
		}
		stage("Push Image") {
			when {
                branch 'main'
            }
			steps {
				script {
					def version = sh(script: "node -p \"require('./package.json').version\"", returnStdout: true).trim()
					def exists = {
						def result = sh(script: "curl --silent -f --head -lL https://hub.docker.com/v2/repositories/thisisnothappening/nodejs-encyclopedia-project/tags/${version}/", returnStatus: true)
						return result == 0
					}
					def userInput
					if (exists()) {
						// error("An image with the tag '${version}' already exists")
						userInput = input(
							id: 'userInput',
							message: "An image with the tag '${version}' already exists. Are you sure you want to override the existing version?",
							parameters: [
								string(name: 'Preferred version:', defaultValue: '', description: 'Leave this field empty if you want to keep the default tag.')
							]
						)
					} else {
						userInput = input(
							id: 'userInput',
							message: "The Docker image tag will be: ${version}",
							parameters: [
								string(name: 'Preferred version:', defaultValue: '', description: 'Leave this field empty if you want to keep the default tag.')
							]
						)
					}
					def preferredVersion = userInput
					if (!preferredVersion.isEmpty()) {
						version = preferredVersion
					}
					withCredentials([
						string(credentialsId: 'docker-login-password', variable: 'DOCKER_PASSWORD')
						]) {
						sh "docker build -t nodejs-encyclopedia-project:latest -f Dockerfile.start ."
						sh "docker tag nodejs-encyclopedia-project:latest thisisnothappening/nodejs-encyclopedia-project:latest"
						sh "docker tag nodejs-encyclopedia-project:latest thisisnothappening/nodejs-encyclopedia-project:${version}"
						sh 'docker login --username thisisnothappening --password $DOCKER_PASSWORD'
						sh "docker push thisisnothappening/nodejs-encyclopedia-project:latest"
						sh "docker push thisisnothappening/nodejs-encyclopedia-project:${version}"
						sh "docker image prune -f"
					}
				}
			}
		}
		stage("Deploy") {
			when {
                branch 'main'
            }
		    steps{
		        withCredentials([
					sshUserPrivateKey(credentialsId: 'aws-vm-key', keyFileVariable: 'KEYFILE'),
					string(credentialsId: 'ec2-ssh-user-and-dns', variable: 'TOKEN')
					]) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no -i $KEYFILE $TOKEN '
                        cd .server &&
                        sudo docker-compose stop backend &&
                        sudo docker container prune -f &&
                        sudo docker-compose up -d &&
                        sudo docker image prune -f
                        '
                    '''
				}
		    }
			// this doesn't work:
			post {
				success {
					emailext body: "Your app has been deployed! \uD83D\uDE03",
							subject: "Deployment Notification",
							to: "negoiupaulica21@gmail.com"
				}
    		}
		}
	}
}
