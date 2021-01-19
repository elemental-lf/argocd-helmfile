provisioners:
  files:
    Dockerfile:
      source: Dockerfile.tpl
      arguments:
        argocd_version: "{{ .argocd.version }}"
        helmfile_version: "{{ .helmfile.version }}"
    goss/goss.yaml:
      source: goss/goss.yaml.tpl
      arguments:
        argocd_version: "{{ .argocd.version }}"
        helmfile_version: "{{ .helmfile.version }}"

dependencies:
  argocd:
    releasesFrom:
      githubReleases:
        source: argoproj/argo-cd
    version: "> 1.8.0"
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
    version: "> 0.1"
