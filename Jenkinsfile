pipeline {

    agent { label 'SERVER_1' }

    environment {

        /* Pipeline Parameters */

        ForcePipelineRun = "${params['Force pipeline execution']}" // Parameter to force the execution of the pipeline even if there are no changes

        /* Stage 'Checking Changes' */

        ApplicationPath = "C:\\Projects\\AngularApplication" // URL of the local git repository
        BranchName = 'master' // Branch to monitor for changes

        /* Stages 'Set content Docker image' */

        PipelinePath = "E:\\Jenkins_Root\\workspace\\ProjectName\\AngularApplication" // Path to the Jenkins pipeline workspace
        SSHPrivateKeyPath = "C:\\Users\\sa_jenkins\\.ssh\\id_ed25519" // Path to the SSH private key
        SSHUser = 'sa_jenkins' // SSH user for remote server
        SSHHost = '10.200.2.29' // SSH host for remote server
        RemoteRepositoryPath = "/docker-compose/AngularApplication" // Path to the remote Docker repository
        DockerImageName = "angular_application" // Name of the Docker image

        setContentDockerImageScript = '"bat\\SetContentDockerImage.bat" ' +
                                      '%PipelinePath% ' +
                                      '%ApplicationPath% ' +
                                      '%SSHPrivateKeyPath% ' +
                                      '%SSHUser% ' +
                                      '%SSHHost% ' +
                                      '%RemoteRepositoryPath%'

        /* Stage 'Create and Deploy Docker image' */

        DockerImageTag = "1.${BUILD_ID}"
        DockerComposeFile = "docker-compose.yaml"
        EnvFile = "ANGULAR_APPLICATION.var"

        createAndDeployDockerImageScript = '"bat\\CreateAndDeployDockerImage.bat" ' +
                                           '%SSHPrivateKeyPath% ' +
                                           '%SSHUser% ' +
                                           '%SSHHost% ' +
                                           '%RemoteRepositoryPath% ' +
                                           '%DockerImageTag% ' +
                                           '%EnvFile% ' + 
                                           '%DockerComposeFile%'

        /* Stage 'Post' */

        deleteOldDockerLocalImagesScript = '"bat\\DeleteOldDockerLocalImages.bat" ' +
                                           '%SSHPrivateKeyPath% ' +
                                           '%SSHUser% ' +
                                           '%SSHHost% ' +
                                           '%RemoteRepositoryPath%'

    }

    stages {

        stage('Checking Changes') {

            steps {

                echo 'Start Checking Changes'

                script {

                    dir("${env.ApplicationPath}") { 

                        def changes = powershell(script: """
                            git fetch origin
                            echo (git diff --name-only ${env.BranchName} origin/${env.BranchName} | Measure-Object -Line).Lines
                        """, returnStdout: true).trim()

                        if (changes != "0") {

                            echo "Se encontraron cambios en la rama ${env.BranchName}. Continuando..."
                            env.hasChanges = "true"

                        } else {

                            echo "No hay cambios en la rama ${env.BranchName}. No se ejecutaran los siguientes stages."
                            env.hasChanges = "false"

                            if (env.ForcePipelineRun != "true") {

                                currentBuild.result = 'NOT_BUILT'

                            }

                        }

                    }

                }

                echo 'End Checking Changes'

            }

        }

        stage('Update Changes') {

            when {
                expression { return env.hasChanges == "true" || env.ForcePipelineRun == "true" }
            }

            steps {

                echo 'Start Update Changes'

                dir("${env.ApplicationPath}") {

                    bat """
                        git pull origin ${env.BranchName}
                    """

                }

                echo 'End Update Changes'

            }

        }

        stage('Set content Docker image') {

            when {
                expression { return env.hasChanges == "true" || env.ForcePipelineRun == "true" }
            }

            steps {

                echo 'Start Set content Docker image'

                script {

                    bat label: 'Set content Docker image Script',
                    script: "${env.setContentDockerImageScript}"

                }

                echo 'End Set content Docker image'

            }

        }

        stage('Create and Deploy Docker image') {

            when {
                expression { return env.hasChanges == "true" || env.ForcePipelineRun == "true" }
            }

            steps {

                echo 'Start Create and Deploy Docker image'

                script {

                    bat label: 'Create and Deploy Docker image Script',
                    script: "${env.createAndDeployDockerImageScript}"

                }

                echo 'End Create and Deploy Docker image'

            }

        }

    }

    post {

        success {

            script {

                if(env.hasChanges == "true") {

                    bat label: 'Delete old Docker local images Script',
                    script: "${env.deleteOldDockerLocalImagesScript}"

                }

            }

            echo "Application deployed successfully."
        
        }

        failure {
            echo "Failed to deploy the application."
        }

    }

}
