#!/bin/sh
# ==============================================================================
# Description: Entrypoint del contenedor web nginx (app Angular). Arranca nginx
#   en primer plano como PID 1 para recibir senales de Docker correctamente.
# Author: nehemias salazar <nehemiassala@gmail.com>
# Usage: ENTRYPOINT ["/entrypoint.sh"] (invocado por Docker al iniciar el contenedor)
# Env Vars: ninguna requerida
# Dependencies: nginx (imagen nginx:1.27-alpine)
# ==============================================================================

set -eu

exec nginx -g 'daemon off;'
