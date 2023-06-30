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
					if (exists()) {
						error("An image with the tag '${version}' already exists")
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
			post {
				failure {
					emailext subject: "Pipeline Failed: ${env.JOB_NAME}",
							to: "negoiupaulica21@gmail.com",
							body: "The Jenkins pipeline ${env.JOB_NAME} has failed.",
							attachLog: true
				}
				success {
					emailext subject: "Deployment Notification",
							to: "negoiupaulica21@gmail.com",
							body: "Your app has been deployed!",
							attachLog: true
				}
			}
		}
	}
}
