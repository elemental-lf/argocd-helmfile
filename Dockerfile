FROM argoproj/argocd:v2.4.11

LABEL version="2.4.11-0.145.4-a178869278"
LABEL argocd_version="2.4.11"
LABEL helmfile_version="0.145.4"
LABEL kubectl_version="1.25.0"
LABEL sops_version="3.7.3"
LABEL helm_diff_version="3.5.0"
LABEL version_digest="a178869278"
LABEL maintainer="lf@elemental.net"

# Switch to root for the ability to perform install
USER root

ARG HELMFILE_VERSION=0.145.4
ARG KUBECTL_VERSION=1.25.0
ARG SOPS_VERSION=3.7.3
ARG HELM_DIFF_VERSION=3.5.0
# Install tools needed for your repo-server to retrieve & decrypt secrets, render manifests
# (e.g. curl, awscli, gpg, sops)
COPY argocd-helmfile.sh /usr/local/bin/argocd-helmfile
RUN apt-get update && \
    apt-get install -y curl gpg apt-utils git-crypt joe && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    curl -o /usr/local/bin/helmfile -L https://github.com/roboll/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_linux_amd64 && \
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

