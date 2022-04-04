FROM argoproj/argocd:v2.3.3

LABEL version="2.3.3-0.144.0"
LABEL maintainer="lf@elemental.net"

# Switch to root for the ability to perform install
USER root

ARG HELMFILE_VERSION=v0.144.0
ARG KUBECTL_VERSION=1.18.10
ARG SOPS_VERSION=3.3.1
ARG HELM_DIFF_VERSION=3.1.3
# Install tools needed for your repo-server to retrieve & decrypt secrets, render manifests
# (e.g. curl, awscli, gpg, sops)
COPY argocd-helmfile.sh /usr/local/bin/argocd-helmfile
RUN apt-get update && \
    apt-get install -y curl gpg apt-utils git-crypt joe && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    curl -o /usr/local/bin/helmfile -L https://github.com/roboll/helmfile/releases/download/${HELMFILE_VERSION}/helmfile_linux_amd64 && \
    curl -o /usr/local/bin/sops -L https://github.com/mozilla/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux && \
    curl -o /usr/local/bin/kubectl -L https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/helmfile && \
    chmod +x /usr/local/bin/sops && \
    chmod +x /usr/local/bin/argocd-helmfile

# Switch back to non-root user
USER argocd

RUN helm plugin install https://github.com/databus23/helm-diff --version v${HELM_DIFF_VERSION} && \
    helm plugin install https://github.com/futuresimple/helm-secrets && \
    helm plugin install https://github.com/hypnoglow/helm-s3.git && \
    helm plugin install https://github.com/mumoshu/helm-x  && \
    helm plugin install https://github.com/aslafy-z/helm-git.git

