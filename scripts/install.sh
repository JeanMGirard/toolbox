#!/bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/setup-tool.sh"

clear

set +e

# trap "cd '$PWD_DIR' && echo ERR trap fired!" ERR

PWD_DIR="$(pwd)"
PKG_DIR="$HOME/.config"
SUDO_CMD=""

# setup::clear-installed
# cd /tmp

export ARCH=$(case $(uname -m) in x86_64) echo -n amd64 ;; aarch64) echo -n arm64 ;; *) echo -n $(uname -m) ;; esac)
export OS=$(uname | awk '{print tolower($0)}')

GO_VERSION="1.18";
NODE_VERSION="18.12.1";
TF_VERSION='1.2.8';
TG_VERSION='0.38.9';
TERRAFILE_VERSION='0.7';
TF_DOCS_VERSION='0.16.0';
TFSEC_VERSION="1.27.6"
KUBECTL_VERSION='stable';
# KUBECTL_PLUGINS='view-secret view-allocations ctx switch-config ssm-secret service-tree rbac-view rbac-tool operator minio ktop janitor graph fleet doctor bulk-action blame creyaml cert-manager change-ns'
KREW_PLUGINS=("ingress-nginx" "ktop" "ctx" "graph" "blame" "cert-manager" "ssm-secret" "view-allocations" "doctor")
GOMPLATE_VERSION="3.11.2";
INSTALLED_PACKAGES="";

JAVA_VERSION="17.0.4-tem";
MAVEN_VERSION="3.8.6";
GROOVY_VERSION="4.0.4";
GRADLE_VERSION="7.5.1";


mkdir -p ~/.profile.d $HOME/.profile.d "$PKG_DIR"
mkdir -p ~/.ssh ~/bin
mkdir -p ~/packages ~/packages/java

if [[ ! -z "$WSL_DISTRO_NAME" ]]; then
	echo "Running in WSL"
	# GZIP fix
	echo -en '\x10' | $SUDO_CMD dd of=/usr/bin/gzip count=1 bs=1 conv=notrunc seek=$((0x189))
fi


setup::install-pkgs \
	openssl bash-completion git jq zip unzip curl \
	cmake pass keychain hub ssh-askpass dos2unix \
	peco fzf jsonnet graphviz

setup::install-pkg net-tools --test "ifconfig"




if [[ ! -f ~/.ssh/known_hosts ]]; then
	echo "First run"

	ssh-keyscan -H gitlab.com >> ~/.ssh/known_hosts
	ssh-keyscan -H github.com >> ~/.ssh/known_hosts

	$SUDO_CMD `setup::cmd_update`;
	$SUDO_CMD `setup::cmd_upgrade`;
	if command -v apt-get &> /dev/null; then
		$SUDO_CMD apt-get install -y apt-transport-https ca-certificates software-properties-common
		$SUDO_CMD apt-get autoremove  -y
	fi
fi


# ===================================================================
echo -e "\n====== Installing requirements ==================" && {
	setup::install-pkg gnupg --test 'gpg'
  setup::install-pkg python3-pip --test 'pip3'

	setup::install-pkg rustup --test "cargo" "$(cat <<-'EOF'
		if [[ ! -z "$WSL_DISTRO_NAME" ]]; then
			curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
		else
			curl https://sh.rustup.rs -sSf | sh
		fi;
		source $HOME/.cargo/env
		# echo 'source $HOME/.cargo/env' >> ~/.profile
	EOF
	)"

}




# ===================================================================
echo -e "\n====== Installing Go ==================" && {
	setup::install-pkg go "$(cat <<-'EOF'
		curl -Ls https://dl.google.com/go/go${GO_VERSION:-1.18}.linux-amd64.tar.gz -o go.linux-amd64.tar.gz;
		$SUDO_CMD rm -rf /usr/local/go;
		$SUDO_CMD tar -C /usr/local -xzf go.linux-amd64.tar.gz;
		mkdir -p $HOME/go $HOME/go/bin;
		rm go.linux-amd64.tar.gz;

		cat > $HOME/.profile.d/go <<-EOF2
			#!/bin/bash

			# ====== GOLANG ====================
			export GOVERSION=go${GO_VERSION:-1.18};
			export GO_INSTALL_DIR=/usr/local/go;
			export GOROOT=/usr/local/go;
			export GOPATH=\$HOME/go;
			export GO111MODULE="on";
			export GOSUMDB=off;

			[[ "\$PATH" != *":\$GOROOT"* ]] && export PATH="\$PATH:\$GOROOT/bin";
			[[ "\$PATH" != *":\$GOPATH/bin"* ]] && export PATH="\$PATH:\$GOPATH/bin";
			# =================================="
		EOF2

		. $HOME/.profile.d/go
	EOF
	)"

	# setup::install-pkg goreleaser "curl -sfL https://goreleaser.com/static/run | $SUDO_CMD bash"
	setup::install-pkg dep "curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh"

	URL="https://github.com/hairyhenderson/gomplate/releases/download/v${GOMPLATE_VERSION:-3.11.2}/gomplate_linux-amd64"
	setup::install-pkg gomplate "$SUDO_CMD curl -o /usr/local/bin/gomplate -sSL $URL  && $SUDO_CMD chmod 755 /usr/local/bin/gomplate"
}



# ===================================================================
echo -e "\n====== Installing Java ==================" && {
	setup::install-pkg sdkman --test "sdk" "$(cat <<-'EOF'
	 	curl -s https://get.sdkman.io | bash
		source $HOME/.sdkman/bin/sdkman-init.sh
	EOF
	)"
	setup::install-pkg java   "sdk install java $JAVA_VERSION;  		sdk default java $JAVA_VERSION;"
	setup::install-pkg maven  "sdk install maven $MAVEN_VERSION;  	sdk default maven $MAVEN_VERSION;"
	setup::install-pkg groovy "sdk install groovy $GROOVY_VERSION; 	sdk default groovy $GROOVY_VERSION;"
	setup::install-pkg gradle "sdk install gradle $GRADLE_VERSION; 	sdk default gradle $GRADLE_VERSION;"
}

# ===================================================================
#echo -e "\n====== Installing NodeJs ==================" && {
#	export NVM_DIR="$HOME/.nvm";
#	[ -s "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh";
#
#	setup::install-pkg nvm "$(cat <<-'EOF'
#		curl -Lso- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash;
#
#		export NVM_DIR="$HOME/.nvm";
#		[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh";  # This loads nvm;
#		[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion";  # This loads nvm bash_completion;
#	EOF
#	)"
#
#	setup::install-pkg node "$(cat <<-'EOF'
#		nvm install "${NODE_VERSION:-16.15.1}";
#  	nvm use "${NODE_VERSION:-16.15.1}";
#  	nvm alias default "${NODE_VERSION:-16.15.1}";
#		npm install --location=global npm
#	EOF
#	)"
#}
# ===================================================================
echo -e "\n====== Installing terraform tools ==================" && {
	setup::install-pkg tgenv "git clone https://github.com/JeanMGirard/tgenv.git ~/.tgenv"
	setup::install-pkg tfenv "git clone https://github.com/tfutils/tfenv.git ~/.tfenv"

	chmod +x ~/.tgenv/bin/* ~/.tfenv/bin/*
	export PATH="$PATH:$HOME/.tfenv/bin/:$HOME/.tgenv/bin/";

	setup::install-pkg terraform  "tfenv install ${TF_VERSION:-1.2.8}; tfenv use ${TF_VERSION:-1.2.8};"
	setup::install-pkg terragrunt "tgenv install ${TG_VERSION:-0.38.9};tgenv use ${TG_VERSION:-0.38.9};"
	setup::install-pkg tfsec 			"curl -LOs https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION:-1.27.6}/tfsec-linux-amd64 && chmod +x tfsec-linux-amd64 && $SUDO_CMD mv tfsec-linux-amd64 /usr/local/bin/tfsec"
	setup::install-pkg terraform-docs "$(cat <<-'EOF'
		curl -Ls "https://github.com/terraform-docs/terraform-docs/releases/download/v${TF_DOCS_VERSION:-0.16.0}/terraform-docs-v${TF_DOCS_VERSION:-0.16.0}-$(uname)-amd64.tar.gz" | $SUDO_CMD tar xz -C /usr/local/bin/;
		$SUDO_CMD chmod +x /usr/local/bin/terraform-docs;
	EOF
	)"
	setup::install-pkg tflint "curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash"
	setup::install-pkg infracost "curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh"
	setup::install-pkg inframap "$(cat <<-'EOF'
		curl -Ls https://github.com/cycloidio/inframap/releases/download/v0.6.7/inframap-linux-amd64.tar.gz | $SUDO_CMD tar xz -C /usr/local/bin/
		$SUDO_CMD mv /usr/local/bin/inframap-linux-amd64 /usr/local/bin/inframap;
		$SUDO_CMD chmod +x /usr/local/bin/inframap;
	EOF
	)"

	cat > $HOME/.profile.d/terraform <<-EOF
		#!/bin/bash

		export PATH="\$PATH:\$HOME/.tfenv/bin/:\$HOME/.tgenv/bin/";
		alias tg='terragrunt';
		alias tf='terraform';
		alias tfdocs='terraform-docs';
	EOF

	. "$HOME/.profile.d/terraform"
}
echo -e "\n====== Installing developer tools ==================" && {
	setup::install-pkg ytt "curl -s -L https://carvel.dev/install.sh | $SUDO_CMD K14SIO_INSTALL_BIN_DIR=/usr/local/bin bash"
	setup::install-pkg trunk "curl https://get.trunk.io -fsSL | bash"
	setup::install-pkg shfmt "setup::install-go mvdan.cc/sh/v3/cmd/shfmt@latest"

	setup::install-pkg pre-commit "setup::install-pip pre-commit"
	setup::install-pkg hygen "setup::install-npm hygen"
	setup::install-pkg task '$SUDO_CMD sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin'

	setup::install-pkg cheat '$SUDO_CMD curl -s -o /usr/local/bin/cheat -L https://raw.githubusercontent.com/alexanderepstein/Bash-Snippets/master/cheat/cheat && $SUDO_CMD chmod +x /usr/local/bin/cheat'

	[[ ! -d "$PKG_DIR/git-extra-commands" ]] && setup::install-pkg git-extra-commands "`$(cat <<-'EOF'
		git clone https://github.com/unixorn/git-extra-commands.git "$PKG_DIR/git-extra-commands"
		cat > $HOME/.profile.d/mod.git-extra-commands <<-EOF2
			#!/bin/bash

			[[ "\$PATH\" != *\"packages/git-extra-commands/bin/bin\"* ]] && export PATH=\$PATH:\$HOME/packages/git-extra-commands/bin;
			alias git-extra-commands='ls -a \$HOME/packages/git-extra-commands/bin'
		EOF2
	EOF
	)`"
}
# ===================================================================
echo -e "\n====== Installing devOps tools ==================" && {
	setup::install-pkg aws "$(cat <<-'EOF'
		curl -Ls https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip;
		unzip awscliv2.zip;
		$SUDO_CMD ./aws/install;
		rm -rf ./aws ./awscliv2.zip;
	EOF
	)"

	setup::install-pkg kubectl "$(cat <<-'EOF'
		if [[ -z "$KUBECTL_VERSION" || "$KUBECTL_VERSION" == "stable" ]]; then KUBECTL_VERSION="$(curl -Ls https://dl.k8s.io/release/stable.txt)"; fi;
		curl -sOSL "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl";
		curl -sOSL "https://dl.k8s.io/$KUBECTL_VERSION/bin/linux/amd64/kubectl.sha256";
		echo "$(if [[ -f kubectl.sha256 ]]; then cat kubectl.sha256; else echo ''; fi)  kubectl" | sha256sum --check;
		chmod +x kubectl && $SUDO_CMD mv kubectl /usr/local/bin/;
		rm kubectl.sha256;
	EOF
	)"
	setup::install-pkg helm 'curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash'
	setup::install-pkg minikube 'curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube && $SUDO_CMD mv minikube /usr/local/bin/'
	setup::install-pkg eksctl "curl -Ls \"https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz\" | tar xz -C /tmp && $SUDO_CMD mv /tmp/eksctl /usr/local/bin"
	setup::install-pkg helmfile "curl -Ls https://github.com/helmfile/helmfile/releases/download/v0.145.2/helmfile_0.145.2_linux_amd64.tar.gz | $SUDO_CMD tar xz -C /usr/local/bin/ "
	setup::install-pkg kind "go install sigs.k8s.io/kind@v0.17.0"


	setup::install-pkg ansible
	setup::install-pkg sops '$SUDO_CMD curl -s -o /usr/local/bin/sops -L https://github.com/mozilla/sops/releases/download/v3.7.3/sops-v3.7.3.linux.amd64 && $SUDO_CMD chmod +x /usr/local/bin/sops'
	setup::install-pkg gitlab-ci-local "$(cat <<-'EOF'
		if command -v apt-get &> /dev/null; then
			curl -s "https://firecow.github.io/gitlab-ci-local/ppa/pubkey.gpg" | $SUDO_CMD apt-key add -
			$SUDO_CMD curl -s -o /etc/apt/sources.list.d/gitlab-ci-local.list "https://firecow.github.io/gitlab-ci-local/ppa/gitlab-ci-local.list"
			$SUDO_CMD apt-get update
			$SUDO_CMD apt-get install gitlab-ci-local
		# else
		# 	npm i --location=global gitlab-ci-local
		fi
	EOF
	)"

	setup::install-pkg istioctl "$(cat <<-'EOF'
		curl -L https://istio.io/downloadIstio | sh -
    chmod +x istio-1.15.1/bin/istioctl && $SUDO_CMD mv -r ./istio-1.15.1 /usr/local/bin/istio-1.15.1
    echo 'export PATH="\$PATH:/usr/local/bin/istio-1.15.1/bin"' >> "$HOME/.profile"
	EOF
  )"

	[[ -z "$(kubectl krew)" ]] && setup::install-pkg 'kubectl-krew' "$(cat <<-'EOF'
		(
			set -x; cd "$(mktemp -d)" &&
			OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
			ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
			KREW="krew-${OS}_${ARCH}" &&
			curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
			tar zxvf "${KREW}.tar.gz" &&
			"${KREW}" install krew
		)
		export PATH="$PATH:${KREW_ROOT:-$HOME/.krew}/bin"
		echo 'export PATH="\$PATH:\${KREW_ROOT:-\$HOME/.krew}/bin"' >> ~/.profile
		kubectl krew install $KREW_PLUGINS
	EOF
	)"
}
# ===================================================================
echo -e "\n====== Installing Git tools ==================" && {
	setup::install-pkg git-extras
	setup::install-rust git-cliff
	setup::install-pkg git-secret
}
# ===================================================================
# Setup
# echo -e " * Starting setup "; then
# pre-commit install
# pet configure
# snipkit config init
# snipkit manager add

echo -e "\n====== Installation completed =================="
cd "$PWD_DIR"
echo "$(setup::list-installed)"
cat << 'EOF'


 # If this your first install, add the following to your .profile file.
 [ -d ~/.profile.d/ ] && for file in $(find ~/.profile.d/ -type f) ; do source "$file"; done

EOF
