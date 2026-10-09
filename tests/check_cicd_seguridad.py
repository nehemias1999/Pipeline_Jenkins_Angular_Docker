#!/usr/bin/env python3
# ==============================================================================
# Description: Verifica REQ cicd-seguridad (4 escenarios de la spec): escaneo
#   multi-directorio de secretos (Jenkinsfile + bat/ + sh/ + docker/, excluye
#   solo documentacion *.md), parameters/options, SSH seguro con guardas,
#   stages Lint + Verify Deploy con healthcheck/rollback y post completo.
# Author: sdd-implementer
# Usage: python3 tests/check_cicd_seguridad.py [--root DIR]
# Env Vars: ninguna requerida.
# Dependencies: python3 (stdlib unicamente)
# Output / Exit codes: reporte por escenario en STDOUT; exit 0 todo verde,
#   exit 1 algun escenario en rojo (fallos detallados en STDERR).
# ==============================================================================
"""Verificacion del requisito cicd-seguridad contra el repo real.

Replica el grep literal de la spec sobre Jenkinsfile + bat/ + sh/ + docker/
(excluye solo documentacion *.md) y comprueba los 4 escenarios del contrato
de interfaz. Sin mocks: opera sobre el contenido real de los archivos.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

SECRET_PATTERNS = [
    r"sa_jenkins",
    r"10\.200\.",
    r"C:\\+Users",
    r"E:\\+Jenkins",
]

# Alcance literal del escenario 1 de la spec (solo se excluye documentacion).
SCAN_SCOPES = ("Jenkinsfile", "bat", "sh", "docker")


def iter_scan_files(root: Path) -> list[Path]:
    """Archivos del alcance del escaneo, excluyendo solo documentacion."""
    found: list[Path] = []
    for scope in SCAN_SCOPES:
        target = root / scope
        if target.is_file():
            found.append(target)
        elif target.is_dir():
            for path in sorted(target.rglob("*")):
                if path.is_file() and path.suffix.lower() != ".md":
                    found.append(path)
    return found


def check_sin_secretos(root: Path, text: str) -> list[str]:
    """Revisa secretos en Jenkinsfile + bat/ + sh/ + docker/ y credentials()."""
    errors: list[str] = []
    for path in iter_scan_files(root):
        try:
            content = path.read_text(encoding="utf-8", errors="strict")
        except (UnicodeDecodeError, OSError):
            continue
        for lineno, line in enumerate(content.splitlines(), start=1):
            for pat in SECRET_PATTERNS:
                if re.search(pat, line):
                    rel = path.relative_to(root)
                    errors.append(f"secreto literal {pat} en {rel}:{lineno}")
    for required in (
        "credentials('ssh-remote-user')",
        "credentials('ssh-remote-host')",
        'sshUserPrivateKey(credentialsId: \'ssh-deploy-key\'',
    ):
        if required not in text:
            errors.append(f"falta binding requerido: {required}")
    return errors


def check_parameters_options(text: str) -> list[str]:
    """Revisa parameters FORCE_PIPELINE y options con los 4 elementos."""
    errors: list[str] = []
    if "parameters" not in text or "booleanParam('FORCE_PIPELINE'" not in text:
        errors.append("falta parameters con booleanParam('FORCE_PIPELINE')")
    for opt in (
        "timestamps()",
        "timeout(time: 30, unit: 'MINUTES')",
        "disableConcurrentBuilds()",
        "buildDiscarder(logRotator(numToKeepStr: '20'))",
    ):
        if opt not in text:
            errors.append(f"falta option: {opt}")
    if "params['Force pipeline execution']" in text:
        errors.append("referencia legacy params['Force pipeline execution']")
    if "params.FORCE_PIPELINE" not in text:
        errors.append("ningun when usa params.FORCE_PIPELINE")
    return errors


def check_ssh_seguro(text: str) -> list[str]:
    """Revisa SSH/SCP con StrictHostKeyChecking+BatchMode y guardas rm-rf."""
    errors: list[str] = []
    ssh_lines = [
        ln for ln in text.splitlines() if re.search(r"\bss[h|cp]\b", ln) or "ssh " in ln or "scp " in ln
    ]
    ssh_cmds = [ln for ln in ssh_lines if re.search(r"(^|[^a-zA-Z])s(sh|cp)\s", ln)]
    if not ssh_cmds:
        errors.append("no hay invocaciones ssh/scp directas que auditar")
    for ln in ssh_cmds:
        if "StrictHostKeyChecking=yes" not in ln or "BatchMode=yes" not in ln:
            errors.append(f"ssh/scp sin opciones seguras: {ln.strip()[:100]}")
    for i, ln in enumerate(text.splitlines()):
        if "rm -rf" in ln:
            window = "\n".join(text.splitlines()[max(0, i - 2) : i + 1])
            if '[ -n "' not in window and "[ -n '" not in window:
                errors.append(f"rm -rf sin guarda: {ln.strip()[:100]}")
    return errors


def check_gates(text: str) -> list[str]:
    """Revisa stages Lint y Verify Deploy + healthcheck/rollback + post."""
    errors: list[str] = []
    if "stage('Lint')" not in text and 'stage("Lint")' not in text:
        errors.append("falta stage Lint")
    if "Verify Deploy" not in text:
        errors.append("falta stage Verify Deploy")
    if "curl" not in text or "--fail" not in text:
        errors.append("falta healthcheck curl --fail")
    if "NGINX_HOST" not in text or "NGINX_PORT" not in text:
        errors.append("healthcheck no usa NGINX_HOST:NGINX_PORT")
    if "retry" not in text:
        errors.append("healthcheck sin reintentos (retry)")
    if "FAILURE" not in text:
        errors.append("fallo de verify no marca FAILURE")
    if "rollback" not in text.lower():
        errors.append("falta rollback a imagen previa")
    for block in ("success", "failure", "always"):
        if not re.search(rf"^\s*{block}\s*\{{", text, re.M):
            errors.append(f"falta bloque post.{block}")
    if "archiveArtifacts" not in text:
        errors.append("falta archiveArtifacts en post")
    return errors


def main() -> int:
    """Punto de entrada CLI: ejecuta los 4 escenarios y reporta."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root",
        default=str(Path(__file__).resolve().parents[1]),
        help="Raiz del repo (contiene Jenkinsfile)",
    )
    args = parser.parse_args()
    jenkinsfile = Path(args.root) / "Jenkinsfile"
    if not jenkinsfile.is_file():
        print(f"ERROR: no existe {jenkinsfile}", file=sys.stderr)
        return 1
    root = Path(args.root)
    text = jenkinsfile.read_text(encoding="utf-8")
    scenarios = (
        ("1-sin-secretos", check_sin_secretos(root, text)),
        ("2-parameters-options", check_parameters_options(text)),
        ("3-ssh-guardas", check_ssh_seguro(text)),
        ("4-gates-post", check_gates(text)),
    )
    failed = 0
    for name, errors in scenarios:
        if errors:
            failed += 1
            print(f"[{name}] FAIL ({len(errors)})")
            for err in errors:
                print(f"  - {err}", file=sys.stderr)
        else:
            print(f"[{name}] OK")
    print(f"Resultado: {len(scenarios) - failed}/{len(scenarios)} escenarios en verde")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
