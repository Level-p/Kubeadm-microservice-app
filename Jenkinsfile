pipeline {
    agent any

    parameters {
        choice(
            name: 'action',
            choices: ['apply', 'destroy'],
            description: 'Select the Terraform action to perform'
        )
    }

    triggers {
        pollSCM('* * * * *')
    }

    environment {
        PATH = "/var/lib/jenkins/.local/bin:${env.PATH}"
        SLACKCHANNEL = 'varsitix'
        SLACKCREDENTIALS = credentials('slack-cred')

    }

    stages {

        stage('IAC Scan') {
            steps {
                dir('.') {
                    script {
                        sh 'command -v checkov || pip install --quiet checkov'

                        // Print findings to the console AND write the JUnit report
                        def checkovStatus = sh(
                            script: 'checkov -d . --framework terraform --compact -o cli -o junitxml --output-file-path console,checkov-results.xml',
                            returnStatus: true
                        )

                        // Publish the report without turning the build UNSTABLE
                        junit allowEmptyResults: true,
                              skipMarkingBuildUnstable: true,
                              testResults: 'checkov-results.xml'
                        archiveArtifacts artifacts: 'checkov-results.xml', allowEmptyArchive: true

                        if (checkovStatus != 0) {
                            echo 'Checkov found security issues. See the scan output above or the Tests tab.'
                        }
                    }
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir('.') {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Format') {
            steps {
                dir('.') {
                    sh 'terraform fmt -check -recursive'
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('.') {
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('.') {
                    sh 'terraform plan'
                }
            }
        }

        stage('Terraform Action') {
            steps {
                dir('.') {
                    script {
                        sh "terraform ${params.action} -auto-approve"
                    }
                }
            }
        }
    }

    post {
        failure {
            slackSend(
                channel: "${env.SLACKCHANNEL}",
                color: 'danger',
                message: "Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' failed. Check ${env.BUILD_URL}"
            )
        }

        success {
            slackSend(
                channel: "${env.SLACKCHANNEL}",
                color: 'good',
                message: "Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' completed successfully. Check ${env.BUILD_URL}"
            )
        }
    }
}