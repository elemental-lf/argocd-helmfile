#!/bin/bash
#
# Originally based on https://github.com/travisghansen/argo-cd-helmfile/blob/master/src/argo-cd-helmfile.sh.
#
set -eo pipefail

# This is needed so that git crypt finds the keyring
GNUPGHOME=/app/config/gpg/keys/
export GNUPGHOME

function is_bin_in_path() {
  builtin type -P "$1" &> /dev/null
}

# https://unix.stackexchange.com/questions/294835/replace-environment-variables-in-a-file-with-their-actual-values
function variable_expansion() {
  # prefer envsubst if available, fallback to perl
  if is_bin_in_path envsubst; then
    echo -n "${@}" | envsubst
  else
    echo -n "${@}" | perl -pe 's/\$(\{)?([a-zA-Z_]\w*)(?(1)\})/$ENV{$2}/g'
  fi
}

# exit immediately if no phase is passed in
if [[ $# != 1 || ($1 != generate && $1 != init)]]; then
  echo "usage: $0 generate|init" >&2
  exit 1
fi
phase=$1

cat >&2 <<EOF
Phase           : $phase
Helm version    : $(helm version --short)
Helmfile version: $(helmfile --version)
Environment     :
EOF
printenv | egrep '^(ARGOCD_APP_|ARGOCD_ENV_|GNUPGHOME)' | sort | sed 's/^/  /g' >&2

# Set environment variables starting with ARGO_CD_ENV_HELMFILE_EXPORT_ by removing the prefix and exporting them.
while IFS='=' read -r -d '' name value; do
  if [[ $name == ARGO_CD_ENV_HELMFILE_EXPORT_* ]]; then
    name="${name#ARGO_CD_ENV_HELMFILE_EXPORT_}"
    eval "${name}='${value}'; export ${name}"
  fi
done < <(env -0)

# expand nested variables
if [[ -v ARGOCD_ENV_HELMFILE_GLOBAL_OPTIONS ]]; then
  ARGOCD_ENV_HELMFILE_GLOBAL_OPTIONS="$(variable_expansion "${ARGOCD_ENV_HELMFILE_GLOBAL_OPTIONS}")"
fi

if [[ -v ARGOCD_ENV_HELMFILE_TEMPLATE_OPTIONS ]]; then
  ARGOCD_ENV_HELMFILE_TEMPLATE_OPTIONS="$(variable_expansion "${ARGOCD_ENV_HELMFILE_TEMPLATE_OPTIONS}")"
fi

if [[ -v ARGOCD_ENV_HELM_TEMPLATE_OPTIONS ]]; then
  ARGOCD_ENV_HELM_TEMPLATE_OPTIONS="$(variable_expansion "${ARGOCD_ENV_HELM_TEMPLATE_OPTIONS}")"
fi

helmfile="helmfile --helm-binary helm --no-color --allow-no-matching-release"

if [[ "${ARGOCD_APP_NAMESPACE}" ]]; then
  helmfile="${helmfile} --namespace ${ARGOCD_APP_NAMESPACE}"
fi

if [[ "${ARGOCD_ENV_HELMFILE_GLOBAL_OPTIONS}" ]]; then
  helmfile="${helmfile} ${ARGOCD_ENV_HELMFILE_GLOBAL_OPTIONS}"
fi

if [[ -v ARGOCD_ENV_HELMFILE_HELMFILE_PATH ]]; then
  helmfile="${helmfile} -f ${ARGOCD_ENV_HELMFILE_HELMFILE_PATH}"
elif [[ -v ARGOCD_ENV_HELMFILE_HELMFILE ]]; then
  helmfile="${helmfile} -f helmfile.yaml"
fi

case $phase in
  "init")
    if [[ -d .git-crypt ]]; then
      if is_bin_in_path git-crypt; then
        # Ignore any errors from git-crypt, we might not have the right key for example
        git-crypt unlock || true
      else
        echo "WARNING: Repository uses git-crypt but it is not available in the PATH." 2>/dev/null
      fi
    fi

    if [[ -v ARGOCD_ENV_HELMFILE_HELMFILE ]]; then
      # Overwrites the helmfile.yaml in the repository if present
      echo "${ARGOCD_ENV_HELMFILE_HELMFILE}" >helmfile.yaml
    fi

    ${helmfile} deps # includes repos step
    ;;

  "generate")
    # shellcheck disable=SC2086
    ${helmfile} template --skip-deps --args "${ARGOCD_ENV_HELM_TEMPLATE_OPTIONS}" ${ARGOCD_ENV_HELMFILE_TEMPLATE_OPTIONS}
    ;;

  *)
    echo "invalid phase: $phase." >&2
    exit 1
    ;;
esac
