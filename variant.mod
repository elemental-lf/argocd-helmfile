provisioners:
  files:
    Dockerfile:
      source: Dockerfile.tpl
      arguments:
        argocd_version: "{{ .argocd.version }}"
        helmfile_version: "{{ .helmfile.version }}"
        kubectl_version: "{{ .kubectl.version }}"
        helm_diff_version: "{{ .helm_diff.version }}"
        sops_version: "{{ .sops.version }}"
        version_digest: '{{ substr 0 10 (printf "%s-%s-%s-%s-%s" .argocd.version .helmfile.version .kubectl.version .helm_diff.version .sops.version | sha256) }}'
    goss/goss.yaml:
      source: goss/goss.yaml.tpl
      arguments:
        argocd_version: "{{ .argocd.version }}"
        helmfile_version: "{{ .helmfile.version }}"
        kubectl_version: "{{ .kubectl.version }}"
        helm_diff_version: "{{ .helm_diff.version }}"
        sops_version: "{{ .sops.version }}"

dependencies:
  argocd:
    releasesFrom:
      githubReleases:
        source: argoproj/argo-cd
    version: "^2.0.0"
  #argocd:
  #  releasesFrom:
  #    jsonPath:
  #      source: https://api.github.com/repos/argoproj/argo-cd/releases?prereleases=true
  #      versions: "$[*].tag_name"
  #  version: "1.8.0-rc2"
  helmfile:
    releasesFrom:
      githubReleases:
        source: roboll/helmfile
    version: ">0.1"
  kubectl:
    releasesFrom:
      githubReleases:
        source: kubernetes/kubernetes
    version: "^1.23.0"
  helm_diff:
    releasesFrom:
      githubReleases:
        source: databus23/helm-diff 
    version: "^3.0.0"
  sops:
    releasesFrom:
      githubReleases:
        source: mozilla/sops
    version: "^3.7.2"
