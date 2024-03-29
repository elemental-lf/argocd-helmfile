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

# set up an app specific home directory
# helmfile uses this as the base directory to save its cache in the .cache/helmfile subdirectory
# helm uses a global location set by ArgoCD via $HELM_CACHE_HOME, $HELM_CONFIG_HOME, and $HELM_DATA_HOME
export HOME="/tmp/argocd-helmfile/apps/${ARGOCD_APP_NAME}"
if [[ ! -d $HOME ]]; then
  mkdir -p "$HOME"
fi

cat >&2 <<EOF
Phase            : $phase
Helm version     : $(helm version --short)
Helmfile version : $(helmfile --version)
Environment      :
EOF
printenv | grep -E '^(ARGOCD_APP_|ARGOCD_ENV_|KUBE_|GNUPGHOME)' | sort | sed 's/^/  /g' >&2

while IFS='=' read -r -d '' name value; do
  if [[ $name == ARGOCD_ENV_* ]]; then
    name="${name#ARGOCD_ENV_}"
    # shellcheck disable=SC2086
    export ${name}="${value}"
  fi
done < <(env -0)

# expand nested variables
if [[ -v HELMFILE_GLOBAL_OPTIONS ]]; then
  HELMFILE_GLOBAL_OPTIONS="$(variable_expansion "${HELMFILE_GLOBAL_OPTIONS}")"
fi

if [[ -v HELMFILE_TEMPLATE_OPTIONS ]]; then
  HELMFILE_TEMPLATE_OPTIONS="$(variable_expansion "${HELMFILE_TEMPLATE_OPTIONS}")"
fi

if [[ -v HELM_TEMPLATE_OPTIONS ]]; then
  HELM_TEMPLATE_OPTIONS="$(variable_expansion "${HELM_TEMPLATE_OPTIONS}")"
fi

helmfile="helmfile --helm-binary helm --no-color --allow-no-matching-release"

if [[ "${ARGOCD_APP_NAMESPACE}" && ! "${HELMFILE_USE_CONTEXT_NAMESPACE}" ]]; then
  helmfile="${helmfile} --namespace ${ARGOCD_APP_NAMESPACE}"
fi

if [[ "${HELMFILE_GLOBAL_OPTIONS}" ]]; then
  helmfile="${helmfile} ${HELMFILE_GLOBAL_OPTIONS}"
fi

if [[ -v HELMFILE_HELMFILE_PATH ]]; then
  helmfile="${helmfile} -f ${HELMFILE_HELMFILE_PATH}"
elif [[ -v HELMFILE_HELMFILE ]]; then
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

    if [[ -v HELMFILE_HELMFILE ]]; then
      # Overwrites the helmfile.yaml in the repository if present
      echo "${HELMFILE_HELMFILE}" >helmfile.yaml
    fi

    if [[ "${HELMFILE_CACHE_CLEANUP}" ]]; then
      ${helmfile} cache cleanup
    fi

    ${helmfile} deps # includes repos step
    ;;

  "generate")
    # shellcheck disable=SC2086
    ${helmfile} template --skip-deps --args "${HELM_TEMPLATE_OPTIONS} --kube-version=${KUBE_VERSION} \
      --api-versions=${KUBE_API_VERSIONS}" ${HELMFILE_TEMPLATE_OPTIONS}
    ;;

  *)
    echo "invalid phase: $phase." >&2
    exit 1
    ;;
esac
