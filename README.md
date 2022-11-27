# toolbox

## Usage

```shell
docker run \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd):/app" \
  toolbox
```

## Features

* Languages
    * Go 1.19
        * gomplate
        * dep
    * Node
        * nvm
    * Python3
        * pip3
    * java
        * sdkman
* Shells
    * General
        * zip
        * unzip
        * curl
        * jq
        * ytt
        * peco
        * jsonnet
        * fzf
    * Developer tools
        * task (taskfile)
        * cheat
        * nx
        * hygen
        * git
        * git-cliff
        * git-extras
        * git-extra-commands
        * shfmt
        * trunk
        * graphviz
        * pre-commit
        * dos2unix
        * hub (github)
    * CI/CD
        * gitlab-ci-local
    * Secrets
        * sops
        * vault
        * git-secret
    * Cloud providers
        * aws
            * eksctl
        * az
    * Containers
        * docker (must mount docker daemon)
        * kubectl
            * plugins
                * krew
                * ingress-nginx
                * ktop
                * ctx
                * graph
                * blame
                * cert-manager
                * ssm-secret
                * view-allocations
                * doctor
        * helm
            * plugins
                * secrets
                * s3
                * monitor
        * helmfile
        * istioctl
        * kind
        * minikube
  * Build tools
      * packer
      * cmake
      * maven
      * groovy
      * gradle
  * IaC Tools
      * ansible
      * Tfenv (Terraform)
      * Tgenv (Terragrunt)
      * tflint
      * terraform-docs
      * tfsec
      * inframap
      * infracost
    * Network & Monitoring
        * Consul
        * ifconfig (net-tools)
    * Other
        * rclone
* Flow
    * .autoactivate

#### Aliases

| alias  | value          | -   | alias | value |
|--------|----------------|-----|-------|-------|
| tg     | terragrunt     | -   |       |       |
| tf     | terraform      | -   |       |       |
| tfdocs | terraform-docs | -   |       |       |

