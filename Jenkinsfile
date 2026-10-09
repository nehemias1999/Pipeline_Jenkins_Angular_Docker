pipeline {

    agent { label 'SERVER_1' }

    // REQ cicd-seguridad: parametros declarativos (sin valores sensibles literales).
    parameters {
        booleanParam('FORCE_PIPELINE', false, 'Fuerza la ejecucion del pipeline aunque no haya cambios en la rama')
        string(name: 'NGINX_PORT', defaultValue: '8080', description: 'Puerto NGINX expuesto para el healthcheck post-deploy')
    }

    // REQ cicd-seguridad: opciones de robustez del pipeline.
    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    environment {

        // REQ cicd-seguridad: secretos via Jenkins credentials (Secret Text), nunca literales.
        SSH_REMOTE_USER = credentials('ssh-remote-user')
        SSH_REMOTE_HOST = credentials('ssh-remote-host')
        NGINX_HOST = credentials('nginx-host')
        NGINX_PORT = "${params.NGINX_PORT}"

        /* Stage 'Checking Changes' */

        ApplicationPath = "C:\\Projects\\AngularApplication" // URL of the local git repository
        BranchName = 'master' // Branch to monitor for changes

        /* Stages 'Set content Docker image' (PipelinePath = workspace del build; la clave SSH llega por credentials, nunca por ruta literal) */

        RemoteRepositoryPath = "/docker-compose/AngularApplication" // Path to the remote Docker repository
        DockerImageName = "angular_application" // Name of the Docker image

        /* Bloque versionado (REQ versionado-trazabilidad): tag SemVer + SHA corto para trazabilidad. */
        GIT_SHORT_SHA = "${env.GIT_COMMIT?.take(7) ?: 'dev'}"
        DOCKER_IMAGE_TAG = "1.${BUILD_NUMBER}-${GIT_SHORT_SHA}"

        /* Stage 'Create and Deploy Docker image' */

        DockerImageTag = "1.${BUILD_ID}"
        DockerComposeFile = "docker-compose.yaml"
        EnvFile = "ANGULAR_APPLICATION.var"

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

                            if (!params.FORCE_PIPELINE) {

                                currentBuild.result = 'NOT_BUILT'

                            }

                        }

                    }

                }

                echo 'End Checking Changes'

            }

        }

        stage('Lint') {

            steps {

                echo 'Start Lint'

                // REQ cicd-seguridad: gate de calidad, falla el build si faltan artefactos base.
                powershell label: 'Lint pipeline inputs', script: '''
                    $ErrorActionPreference = 'Stop'
                    if (-not (Test-Path 'docker/docker-compose.yaml')) { throw 'Lint: falta docker/docker-compose.yaml' }
                    $var = Get-Content 'docker/ANGULAR_APPLICATION.var' -Raw
                    if ($var -notmatch '(?m)^DOCKER_IMAGE_TAG=') { throw 'Lint: ANGULAR_APPLICATION.var sin clave DOCKER_IMAGE_TAG' }
                    Write-Output 'Lint OK'
                '''

                echo 'End Lint'

            }

        }

        stage('Update Changes') {

            when {
                expression { return env.hasChanges == "true" || params.FORCE_PIPELINE }
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
                expression { return env.hasChanges == "true" || params.FORCE_PIPELINE }
            }

            steps {

                echo 'Start Set content Docker image'

                script {

                    // REQ cicd-seguridad: clave SSH via credentials store (nunca ruta literal).
                    withCredentials([sshUserPrivateKey(credentialsId: 'ssh-deploy-key', keyFileVariable: 'SSH_KEY_FILE')]) {

                        bat label: 'Set content Docker image Script',
                        script: '"bat\\SetContentDockerImage.bat" %WORKSPACE% %ApplicationPath% %SSH_KEY_FILE% %SSH_REMOTE_USER% %SSH_REMOTE_HOST% %RemoteRepositoryPath%'

                    }

                }

                echo 'End Set content Docker image'

            }

        }

        stage('Versionado y trazabilidad') {

            steps {

                echo 'Start Versionado y trazabilidad'

                script {

                    // Bloque versionado (REQ versionado-trazabilidad): genera build-info.json y lo archiva para auditoria.
                    def versionTag = env.DOCKER_IMAGE_TAG ?: "1.${env.BUILD_NUMBER}-${env.GIT_SHORT_SHA}"
                    // Exporta el tag al .var por clave ^DOCKER_IMAGE_TAG= (nunca por numero de linea).
                    def varText = readFile file: 'docker/ANGULAR_APPLICATION.var'
                    if (varText =~ /(?m)^DOCKER_IMAGE_TAG=/) {
                        varText = varText.replaceAll(/(?m)^DOCKER_IMAGE_TAG=.*/, "DOCKER_IMAGE_TAG=${versionTag}")
                    } else {
                        varText = varText + "\nDOCKER_IMAGE_TAG=${versionTag}\n"
                    }
                    writeFile file: 'docker/ANGULAR_APPLICATION.var', text: varText
                    writeFile file: 'build-info.json', text: "{\"commit\": \"${env.GIT_COMMIT}\", \"branch\": \"${env.BRANCH_NAME}\", \"build_tag\": \"${versionTag}\", \"image\": \"${env.DockerImageName}:${versionTag}\", \"timestamp\": \"${new Date().format(\"yyyy-MM-dd'T'HH:mm:ss'Z'\", TimeZone.getTimeZone('UTC'))}\"}"
                    archiveArtifacts artifacts: 'build-info.json, docker/ANGULAR_APPLICATION.var', fingerprint: true

                }

                echo 'End Versionado y trazabilidad'

            }

        }

        stage('Create and Deploy Docker image') {

            when {
                expression { return env.hasChanges == "true" || params.FORCE_PIPELINE }
            }

            steps {

                echo 'Start Create and Deploy Docker image'

                script {

                    // REQ cicd-seguridad: clave SSH via credentials store (nunca ruta literal).
                    withCredentials([sshUserPrivateKey(credentialsId: 'ssh-deploy-key', keyFileVariable: 'SSH_KEY_FILE')]) {

                        // Guarda el tag previo para un eventual rollback del stage Verify Deploy.
                        try {
                            env.PREVIOUS_DOCKER_TAG = bat(script: 'ssh -o StrictHostKeyChecking=yes -o BatchMode=yes -i %SSH_KEY_FILE% %SSH_REMOTE_USER%@%SSH_REMOTE_HOST% "grep \'^DOCKER_IMAGE_TAG=\' %RemoteRepositoryPath%/ANGULAR_APPLICATION.var | cut -d= -f2"', returnStdout: true).trim()
                        } catch (err) {
                            echo "Sin tag previo remoto (deploy inicial): ${err.getMessage()}"
                            env.PREVIOUS_DOCKER_TAG = ''
                        }

                        bat label: 'Create and Deploy Docker image Script',
                        script: '"bat\\CreateAndDeployDockerImage.bat" %SSH_KEY_FILE% %SSH_REMOTE_USER% %SSH_REMOTE_HOST% %RemoteRepositoryPath% %DockerImageTag% %EnvFile% %DockerComposeFile%'

                    }

                }

                echo 'End Create and Deploy Docker image'

            }

        }

        stage('Verify Deploy') {

            when {
                expression { return env.hasChanges == "true" || params.FORCE_PIPELINE }
            }

            steps {

                echo 'Start Verify Deploy'

                script {

                    // REQ cicd-seguridad: clave SSH via credentials store (nunca ruta literal).
                    withCredentials([sshUserPrivateKey(credentialsId: 'ssh-deploy-key', keyFileVariable: 'SSH_KEY_FILE')]) {

                        try {
                            // REQ cicd-seguridad: healthcheck con reintentos contra NGINX_HOST:NGINX_PORT/health.
                            retry(3) {
                                bat label: 'Healthcheck post-deploy',
                                script: 'ssh -o StrictHostKeyChecking=yes -o BatchMode=yes -i %SSH_KEY_FILE% %SSH_REMOTE_USER%@%SSH_REMOTE_HOST% "curl --fail --silent --show-error --max-time 10 http://%NGINX_HOST%:%NGINX_PORT%/health"'
                            }
                            echo 'Verify Deploy: healthcheck OK'
                        } catch (err) {
                            // Healthcheck fallo: rollback a la imagen previa y build en FAILURE.
                            echo "Verify Deploy: healthcheck fallo tras reintentos, rollback a imagen previa (${env.PREVIOUS_DOCKER_TAG})"
                            bat label: 'Rollback a imagen previa',
                            script: 'ssh -o StrictHostKeyChecking=yes -o BatchMode=yes -i %SSH_KEY_FILE% %SSH_REMOTE_USER%@%SSH_REMOTE_HOST% "[ -n \'%PREVIOUS_DOCKER_TAG%\' ] && [ \'%PREVIOUS_DOCKER_TAG%\' != \'/\' ] && cd %RemoteRepositoryPath% && DOCKER_IMAGE_TAG=%PREVIOUS_DOCKER_TAG% docker compose up -d"'
                            currentBuild.result = 'FAILURE'
                            error "Verify Deploy: healthcheck fallo y se ejecuto rollback (${err.getMessage()})"
                        }

                    }

                }

                echo 'End Verify Deploy'

            }

        }

    }

    post {

        // Bloque versionado (REQ versionado-trazabilidad): archivado resiliente en exito o fallo.
        always {

            script {

                try {
                    if (!fileExists('build-info.json')) {
                        def fallbackTag = env.DOCKER_IMAGE_TAG ?: "1.${env.BUILD_NUMBER}-${env.GIT_SHORT_SHA}"
                        writeFile file: 'build-info.json', text: "{\"commit\": \"${env.GIT_COMMIT}\", \"branch\": \"${env.BRANCH_NAME}\", \"build_tag\": \"${fallbackTag}\", \"image\": \"${env.DockerImageName}:${fallbackTag}\", \"timestamp\": \"${new Date().format(\"yyyy-MM-dd'T'HH:mm:ss'Z'\", TimeZone.getTimeZone('UTC'))}\"}"
                    }
                    archiveArtifacts artifacts: 'build-info.json, docker/ANGULAR_APPLICATION.var', allowEmptyArchive: true, fingerprint: true
                } catch (err) {
                    echo "Versionado: no se pudo archivar build-info (${err})"
                }

            }

        }

        success {

            script {

                if(env.hasChanges == "true") {

                    // REQ cicd-seguridad: clave SSH via credentials store (nunca ruta literal).
                    withCredentials([sshUserPrivateKey(credentialsId: 'ssh-deploy-key', keyFileVariable: 'SSH_KEY_FILE')]) {

                        bat label: 'Delete old Docker local images Script',
                        script: '"bat\\DeleteOldDockerLocalImages.bat" %SSH_KEY_FILE% %SSH_REMOTE_USER% %SSH_REMOTE_HOST% %RemoteRepositoryPath%'

                    }

                }

            }

            echo '[notify] success: pipeline verde, artefactos archivados.'
            echo "Application deployed successfully."

        }

        failure {
            echo '[notify] failure: pipeline en rojo, revisar Verify Deploy y rollback.'
            echo "Failed to deploy the application."
        }

    }

}
