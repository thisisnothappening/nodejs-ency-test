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
					def userInput = input(
                        message: 'Select a version bump:',
                        parameters: [
                            choice(name: 'VersionBump', choices: ['major', 'minor', 'patch'], description: '')
                        ]
                    )
					if (userInput.VersionBump != 'major' && userInput.VersionBump != 'minor' && userInput.VersionBump != 'patch') {
                        error("Invalid version bump selected. Pipeline aborted.")
                    }
					def confirmation = input(
                        message: "Are you sure you want to bump the version to ${userInput.VersionBump}?",
                        parameters: [
                            booleanParam(name: 'Confirmation', defaultValue: false, description: '')
                        ]
                    )
					if (!confirmation.Confirmation) {
                        error("Version bump not confirmed. Pipeline aborted.")
                    }
					echo "Version bump: ${userInput.VersionBump}"
					def version = sh(script: "node -p \"require('./package.json').version\"", returnStdout: true).trim()
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
