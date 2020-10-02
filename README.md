# ArgoCD with helmfile

https://argoproj.github.io/argo-cd/

This is an image to use `helmfile` as a ArgoCD config management plugin. It also includes support for `git-crypt`
and will try to decrypt any encrypted files in the source repository if the correct is supplied.

## Usage

Change the ArgoCD repo server image to this image and add the following settings to `argocd-cm`:

```yaml
configManagementPlugins: |
  - name: helmfile
    init:
      command: ["argocd-helmfile"]
      args: ["init"]
    generate:
      command: ["argocd-helmfile"]
      args: ["generate"]
```

## Special Environment Variables

The `argocd-helmfile` accepts some special environment variables which customize how `helm` and `helmfile`
are called and which `helmfile` configuration to use.

* `HELM_TEMPLATE_OPTIONS`     - `helm template --help`
* `HELMFILE_GLOBAL_OPTIONS`   - `helmfile --help`
* `HELMFILE_TEMPLATE_OPTIONS` - `helmfile template --help`
* `HELMFILE`                  - A complete `helmfile.yaml` (ignores standard `helmfile.yaml` and `helmfile.d` if present and
                              takes precendence before `HELMFILE_PATH`)
* `HELMFILE_PATH`             - Path to an alternate `helmfile.yaml` or `helmfile.d` (ignores standard `helmfile.yaml` and
                              `helmfile.d` if present)

## git-crypt

For `git-crypt` to work the necessary GPG private keys need to be supplied to the repo server via a volume. ArgoCD
will automatically load keys from the listed location. If public keys are used too they can be put into a `ConfigMap`
and the volume below needs to be changed to be a projected volume which aggregates both the `ConfigMap` and the `Secret`
into a single directory. 

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: argocd-gpg-keys-secret
  namespace: argocd
type: Opaque
data:
  <hex key-id (16 characters)>: <base64 encoded GPG private key> 
```

```yaml
volumeMounts:
  - name: gpg-keys
    mountPath: /app/config/gpg/source
volumes:
  - name: gpg-keys
    secret:
      secretName: argocd-gpg-keys-secret
```

## Credits

This work is based on:

* https://github.com/chatwork/dockerfiles/tree/master/argocd-helmfile
* https://github.com/travisghansen/argo-cd-helmfile
