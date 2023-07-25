FROM quay.io/argoproj/argocd:v2.7.9

LABEL version="2.7.9-0.155.1-b09aa98530"
LABEL argocd_version="2.7.9"
LABEL helmfile_version="0.155.1"
LABEL kubectl_version="1.27.4"
LABEL sops_version="3.7.3"
LABEL helm_diff_version="3.8.1"
LABEL version_digest="b09aa98530"
LABEL maintainer="lf@elemental.net"

# Switch to root for the ability to perform install
USER root

ARG HELMFILE_VERSION=0.155.1
ARG KUBECTL_VERSION=1.27.4
ARG SOPS_VERSION=3.7.3
ARG HELM_DIFF_VERSION=3.8.1
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
ARG ARGOCD_USER_ID=999
USER $ARGOCD_USER_ID

RUN helm plugin install https://github.com/databus23/helm-diff --version v${HELM_DIFF_VERSION} && \
    helm plugin install https://github.com/jkroepke/helm-secrets && \
    helm plugin install https://github.com/hypnoglow/helm-s3.git && \
    helm plugin install https://github.com/mumoshu/helm-x  && \
    helm plugin install https://github.com/aslafy-z/helm-git.git

