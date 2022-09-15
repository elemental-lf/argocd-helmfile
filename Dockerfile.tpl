FROM argoproj/argocd:v{{ .argocd_version }}

LABEL version="{{ .argocd_version }}-{{ .helmfile_version }}-{{ .version_digest }}"
LABEL argocd_version="{{ .argocd_version }}"
LABEL helmfile_version="{{ .helmfile_version }}"
LABEL kubectl_version="{{ .kubectl_version }}"
LABEL sops_version="{{ .sops_version }}"
LABEL helm_diff_version="{{ .helm_diff_version }}"
LABEL version_digest="{{ .version_digest }}"
LABEL maintainer="lf@elemental.net"

# Switch to root for the ability to perform install
USER root

ARG HELMFILE_VERSION={{ .helmfile_version }}
ARG KUBECTL_VERSION={{ .kubectl_version }}
ARG SOPS_VERSION={{ .sops_version }}
ARG HELM_DIFF_VERSION={{ .helm_diff_version }}
# Install tools needed for your repo-server to retrieve & decrypt secrets, render manifests
# (e.g. curl, awscli, gpg, sops)
COPY argocd-helmfile.sh /usr/local/bin/argocd-helmfile
RUN apt-get update && \
    apt-get install -y curl gpg apt-utils git-crypt joe && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    curl -L https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION}_linux_amd64.tar.gz \
      | tar -C /usr/local/bin -xzf - helmfile && \
    curl -o /usr/local/bin/sops -L https://github.com/mozilla/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux && \
    curl -o /usr/local/bin/kubectl -L https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/helmfile && \
    chmod +x /usr/local/bin/sops && \
    chmod +x /usr/local/bin/argocd-helmfile

# Switch back to non-root user
USER argocd

RUN helm plugin install https://github.com/databus23/helm-diff --version v${HELM_DIFF_VERSION} && \
    helm plugin install https://github.com/jkroepke/helm-secrets && \
    helm plugin install https://github.com/hypnoglow/helm-s3.git && \
    helm plugin install https://github.com/mumoshu/helm-x  && \
    helm plugin install https://github.com/aslafy-z/helm-git.git

