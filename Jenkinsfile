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
					def userInput = input(
						id: 'userInput',
						message: "The Docker image tag will be: ${version}",
						parameters: [
							[$class: 'TextParameterDefinition', defaultValue: '', name: 'Preferred Version']
						]
					)
					def preferredVersion = userInput['Preferred Version']
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
		}
	}
}
