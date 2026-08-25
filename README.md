# Fedora Workstation — Ansible

A production-style Ansible project for configuring a Fedora workstation from a clean installation. It modernizes the original `hhlp/ansible-role-fedora` repository into a reusable role with feature switches, tags, validation, idempotent modules, dependency management, linting, and CI.

## What changed from the original repository

The original project mixed several standalone playbooks for Fedora packages/repositories, Flatpak, Python packages, Docker, and VS Code. This version keeps those functional areas but consolidates them behind one role and one entry point.

Important modernization decisions:

- Uses fully qualified Ansible collection names (`ansible.builtin.*`, `community.general.*`).
- Uses `ansible.builtin.dnf5` for modern Fedora package management.
- Uses `pipx` for end-user Python CLI applications instead of a large `pip install --user` command.
- Installs Docker Engine using Docker's Fedora repository and the current `docker-compose-plugin` / `docker-buildx-plugin` packages.
- Removes Docker Machine and its KVM driver; both belonged to the old Docker Machine workflow.
- Makes third-party repositories, direct remote RPMs, NVIDIA, Docker, VS Code, and AI CLI tooling explicit features rather than unavoidable steps.
- Uses role defaults plus `group_vars` instead of hard-coding workstation choices in tasks.
- Adds `ansible-lint`, `yamllint`, syntax checks, check mode, tags, and GitHub Actions CI.

## Supported target

This role is designed for Fedora Workstation and uses DNF5. By default it accepts any Fedora release; for tightly controlled environments set `fedora_workstation_supported_releases`, for example:

```yaml
fedora_workstation_supported_releases:
  - '43'
  - '44'
```

Individual third-party vendors may support fewer Fedora releases than Fedora itself. Review enabled repositories before upgrading Fedora.

## Controller requirements

Recommended:

- Python 3.11+
- `ansible-core >= 2.18`
- `community.general >= 13`
- `ansible.posix >= 2`

On Fedora:

```bash
sudo dnf install ansible-core git python3-pip
```

Install required Ansible collections:

```bash
ansible-galaxy collection install -r requirements.yml -p .ansible/collections
```

For development/linting:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements-dev.txt
ansible-galaxy collection install -r requirements.yml -p .ansible/collections
```

## Repository layout

```text
.
├── ansible.cfg
├── inventory/
│   └── hosts.yml
├── group_vars/
│   └── all.yml
├── playbooks/
│   ├── local.yml
│   └── workstation.yml
├── roles/
│   └── fedora_workstation/
│       ├── defaults/main.yml
│       ├── handlers/main.yml
│       ├── meta/main.yml
│       └── tasks/
│           ├── main.yml
│           ├── validate.yml
│           ├── base.yml
│           ├── repositories.yml
│           ├── mongodb.yml
│           ├── github_cli.yml
│           ├── browsers.yml
│           ├── balena.yml
│           ├── remote_access.yml
│           ├── warp.yml
│           ├── hashicorp.yml
│           ├── shell.yml
│           ├── local_tools.yml
│           ├── optional_installers.yml
│           ├── packages.yml
│           ├── flatpak.yml
│           ├── python_tools.yml
│           ├── docker.yml
│           ├── vscode.yml
│           ├── nvidia.yml
│           └── ai.yml
├── requirements.yml
├── requirements-dev.txt
├── .ansible-lint
├── .yamllint.yml
├── Makefile
└── site.yml
```

## First run

Clone the repository, install collections, review `group_vars/all.yml`, then run check mode first:

```bash
git clone https://github.com/hhlp/ansible-role-fedora.git
cd ansible-role-fedora
ansible-galaxy collection install -r requirements.yml -p .ansible/collections
ansible-playbook site.yml --check --diff --ask-become-pass
```

Apply the configuration:

```bash
ansible-playbook site.yml --ask-become-pass
```

The provided inventory configures `localhost` with a local connection, so editing `/etc/ansible/hosts` is not required.

## Feature switches

The main switches live in `roles/fedora_workstation/defaults/main.yml` and should normally be overridden in `group_vars/all.yml`:

```yaml
fedora_workstation_enable_repositories: true
fedora_workstation_enable_packages: true
fedora_workstation_enable_flatpak: true
fedora_workstation_enable_python_tools: false
fedora_workstation_enable_docker: false
fedora_workstation_enable_vscode: false
fedora_workstation_enable_nvidia: false
fedora_workstation_enable_ai_clis: false

fedora_workstation_enable_mongodb: false
fedora_workstation_enable_github_cli: true
fedora_workstation_enable_browsers: false
fedora_workstation_enable_balena_etcher: false
fedora_workstation_enable_anydesk: false
fedora_workstation_enable_warp: false
fedora_workstation_enable_terraform: false
fedora_workstation_enable_oh_my_zsh: false
fedora_workstation_enable_zplug: false
fedora_workstation_enable_wcurl: false
```

For a developer workstation, for example:

```yaml
fedora_workstation_enable_docker: true
fedora_workstation_enable_vscode: true
fedora_workstation_enable_python_tools: true

fedora_workstation_profiles:
  - base
  - development
  - python
  - rust
  - virtualization
  - networking

fedora_workstation_extra_packages:
  - podman
```

## Package profiles

The historical workstation package catalog has been split into reusable profiles instead of being installed as one monolithic transaction. The available profiles are:

```text
base
development
python
rust
java
mainframe
virtualization
networking
security
data_science
multimedia
latex
gnome
optional_desktop
```

Select only the profiles required by the target machine:

```yaml
fedora_workstation_profiles:
  - base
  - development
  - python
  - rust
  - virtualization
  - networking
```

The role validates profile names before installation. Unknown profile names fail early with a list of valid profiles. Packages from the selected profiles and `fedora_workstation_extra_packages` are merged and de-duplicated before being passed to `ansible.builtin.dnf5`.

The `mainframe` profile is intentionally empty until Fedora-native packages are explicitly selected for that workflow; mainframe tooling should not be guessed or silently installed.

The legacy source list remains available in `group_vars/legacy-package-catalog.yml.example` for auditing and migration history.

## Tags

Run only selected parts of the configuration:

```bash
ansible-playbook site.yml --tags packages --ask-become-pass
ansible-playbook site.yml --tags flatpak --ask-become-pass
ansible-playbook site.yml --tags docker --ask-become-pass
ansible-playbook site.yml --tags vscode --ask-become-pass
ansible-playbook site.yml --tags mongodb --ask-become-pass
ansible-playbook site.yml --tags github_cli --ask-become-pass
ansible-playbook site.yml --tags terraform --ask-become-pass
ansible-playbook site.yml --tags browsers --ask-become-pass
ansible-playbook site.yml --tags shell --ask-become-pass
```

List available tags:

```bash
ansible-playbook site.yml --list-tags
```

## RPM Fusion and COPR

RPM Fusion is enabled by default because many workstation/media packages rely on it. Disable it if you want a Fedora-only system:

```yaml
fedora_workstation_enable_rpmfusion: false
```

COPR repositories are opt-in:

```yaml
fedora_workstation_copr_repositories:
  - owner: atim
    project: bottom
  - owner: atim
    project: lazygit
```

Do not blindly copy old COPR entries: projects can disappear, change ownership, or become unnecessary when packages move into Fedora.

## Remote RPMs

Direct remote RPM URLs are intentionally empty by default. Version-pinned RPM links age quickly and are a common source of broken fresh-install playbooks.

If a vendor provides a stable, trusted URL:

```yaml
fedora_workstation_remote_rpms:
  - https://zoom.us/client/latest/zoom_x86_64.rpm
```

Prefer a signed vendor repository over a direct RPM whenever one is available.

## Third-party repositories and migrated tools

The original repository's normal third-party repository/tool layer is implemented as real role tasks rather than being left as README-only examples.

| Feature | Task file | Main switch | Tag |
| --- | --- | --- | --- |
| MongoDB 8.0 tools | `tasks/mongodb.yml` | `fedora_workstation_enable_mongodb` | `mongodb` |
| GitHub CLI | `tasks/github_cli.yml` | `fedora_workstation_enable_github_cli` | `github_cli` |
| Brave / Edge / Vivaldi | `tasks/browsers.yml` | `fedora_workstation_enable_browsers` | `browsers` |
| Balena Etcher | `tasks/balena.yml` | `fedora_workstation_enable_balena_etcher` | `balena` |
| AnyDesk | `tasks/remote_access.yml` | `fedora_workstation_enable_anydesk` | `anydesk` |
| Warp terminal | `tasks/warp.yml` | `fedora_workstation_enable_warp` | `warp` |
| HashiCorp / Terraform | `tasks/hashicorp.yml` | `fedora_workstation_enable_terraform` | `terraform` |
| Oh My Zsh / plugins / zplug | `tasks/shell.yml` | `fedora_workstation_enable_oh_my_zsh` | `shell` |
| ACL / kompose / dysk / wcurl | `tasks/local_tools.yml` | feature-specific switches | `local_tools` |
| Script-based optional tools | `tasks/optional_installers.yml` | feature-specific switches | `optional_installers` |

### MongoDB 8.0

The migrated task configures the MongoDB 8.0 Enterprise repository as enabled and the Community repository as disabled by default, then installs:

```yaml
fedora_workstation_mongodb_packages:
  - mongodb-mongosh
  - mongodb-enterprise-tools
  - mongodb-enterprise-database-tools-extra
```

Enable it with:

```yaml
fedora_workstation_enable_mongodb: true
```

### GitHub CLI

The role configures the official GitHub CLI RPM repository and installs `gh`:

```yaml
fedora_workstation_enable_github_cli: true
```

### Browsers

Enable the browser group and then choose individual repositories/packages:

```yaml
fedora_workstation_enable_browsers: true
fedora_workstation_enable_brave: true
fedora_workstation_enable_edge: true
fedora_workstation_enable_vivaldi: true
```

### HashiCorp / Terraform

Terraform is fully implemented in `tasks/hashicorp.yml`; it is not a future placeholder. The task installs the HashiCorp Fedora repository file and then installs `terraform` through DNF5:

```yaml
fedora_workstation_enable_terraform: true
```

### Shell and local tools

The Git-based shell setup preserves Oh My Zsh, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-autocomplete`, and zplug. Local-tool tasks preserve ACL restoration, an optional local `kompose` binary, `dysk`, and `wcurl` plus its man page.

```yaml
fedora_workstation_enable_oh_my_zsh: true
fedora_workstation_enable_zsh_plugins: true
fedora_workstation_enable_zplug: true
fedora_workstation_enable_acl_restore: false
fedora_workstation_enable_local_kompose: false
fedora_workstation_enable_dysk: true
fedora_workstation_enable_wcurl: true
```

### Optional installer scripts

The original source also uses upstream shell installers for Superfile, `fx`, `doggo`, Antigravity CLI, and Warp Agent CLI. They are preserved but disabled by default because mutable `curl | shell` installation is less reproducible than signed RPMs, Git checkouts, or fixed downloads.

```yaml
fedora_workstation_enable_superfile: false
fedora_workstation_enable_fx: false
fedora_workstation_enable_doggo: false
fedora_workstation_enable_antigravity_cli: false
fedora_workstation_enable_warp_agent_cli: false
```

## Flatpak

Flatpak uses `community.general.flatpak` and `community.general.flatpak_remote`. The default method is per-user:

```yaml
fedora_workstation_flatpak_method: user
fedora_workstation_flatpak_packages:
  - com.bitwarden.desktop
  - com.github.tchx84.Flatseal
  - md.obsidian.Obsidian
```

To install system-wide:

```yaml
fedora_workstation_flatpak_method: system
```

## Python tools

Fedora increasingly protects its system Python environment. CLI applications are therefore installed with `pipx` rather than `pip --user`:

```yaml
fedora_workstation_enable_python_tools: true
fedora_workstation_python_tools:
  - black
  - commitizen
  - flake8
  - httpie
```

For scientific/data-science libraries, prefer a project virtual environment, `uv`, Conda/Mamba, or Fedora RPM packages instead of installing them globally through this workstation role.

## Docker

Enable Docker explicitly:

```yaml
fedora_workstation_enable_docker: true
```

The role installs:

```text
docker-ce
docker-ce-cli
containerd.io
docker-buildx-plugin
docker-compose-plugin
```

Use Compose v2 as:

```bash
docker compose version
```

The role can manage `/etc/docker/daemon.json` from structured YAML:

```yaml
fedora_workstation_docker_daemon_config:
  log-driver: journald
  features:
    containerd-snapshotter: true
```

Users added to the `docker` group gain root-equivalent control through the Docker daemon. Only add trusted local users. Log out and back in after group membership changes.

## Visual Studio Code

Enable VS Code explicitly:

```yaml
fedora_workstation_enable_vscode: true
```

The complete historical extension list is preserved as a profile-based catalog. The source list contains 165 entries and resolves to 159 unique extension IDs after de-duplication.

The available VS Code profiles are:

```text
editor_productivity
git_scm
docs_markdown
web
python
c_cpp
java
rust
go
databases
containers_kubernetes
cloud_remote
remote_collaboration
devops_iac
mainframe
ruby
ai
```

VS Code itself remains opt-in, but when enabled the default profile selection includes all profiles so the role reproduces the complete de-duplicated historical catalog. Override `fedora_workstation_vscode_profiles` in `group_vars/all.yml` for a smaller workstation.

For example:

```yaml
fedora_workstation_vscode_profiles:
  - editor_productivity
  - git_scm
  - docs_markdown
  - python
  - devops_iac
  - mainframe
```

The `mainframe` profile contains the Broadcom Code4z/COBOL/JCL/HLASM/REXX/Endevor/debugger extensions together with IBM Z Open Editor and the Zowe extensions.

Add workstation-specific extensions with:

```yaml
fedora_workstation_vscode_extra_extensions:
  - tamasfe.even-better-toml
```

The older `fedora_workstation_vscode_extensions` variable is retained as a compatibility list and is merged with the selected profiles and extras. The six duplicate occurrences from the source list are preserved separately in `fedora_workstation_vscode_duplicate_extensions` for audit only.

At runtime the role validates requested profile names, expands the profile lists, de-duplicates the requested set, queries `code --list-extensions`, and installs only missing extensions for `fedora_workstation_user`. User `settings.json`, keybindings, and snippets are deliberately not overwritten by default.

## NVIDIA

NVIDIA support is opt-in:

```yaml
fedora_workstation_enable_nvidia: true
```

The role assumes RPM Fusion Nonfree is enabled. Secure Boot systems may also require signing/enrolling the NVIDIA kernel module; that workflow should be handled separately rather than hidden inside a generic package task.

## AI command-line tools

AI CLIs are optional because they change frequently and may have separate authentication/subscription requirements:

```yaml
fedora_workstation_enable_ai_clis: true
```

They are installed with npm from the package names in `fedora_workstation_ai_npm_packages`.

## Quality checks

Run:

```bash
make requirements
make syntax
make lint
```

Before applying workstation changes:

```bash
make check
```

Then:

```bash
make apply
```

CI runs YAML lint, Ansible lint, and a syntax check on pushes and pull requests.

## Idempotency

A professional workstation playbook should be safe to rerun. This project therefore prefers Ansible modules over shell commands and declares desired state with `state: present` wherever practical.

Some third-party installers, mutable upstream `latest` versions, GNOME user-session configuration, and vendor repositories can still change independently of this repository. Treat `--check --diff` as part of routine maintenance.

## Migrating your original package list

The original repository contains a very large workstation package catalog and many third-party applications. Do not make that entire historical list a mandatory baseline. Instead, migrate packages you still use into:

```yaml
fedora_workstation_extra_packages:
  - package-one
  - package-two
```

Keep feature-specific packages with their feature (Docker, NVIDIA, VS Code, etc.). This prevents one unavailable package from blocking a complete workstation bootstrap.

## Security notes

- Review every third-party repository and GPG key before enabling it.
- Avoid `disable_gpg_check: true` unless you have a documented reason.
- Avoid `curl | sh` installers in unattended configuration management.
- Do not store API tokens, passwords, or private keys in plain YAML. Use Ansible Vault or an external secret manager.
- Treat Docker group membership as privileged access.
- Pin collection ranges and test upgrades in CI before deploying them broadly.

## License

Use the same license as the repository after confirming the original project's intended license. If publishing this rewrite as a new project, MIT is a common choice for Ansible roles, but the repository owner should make that decision explicitly.


---

# Complete migrated software catalogs

The current role preserves the complete software catalogs from the original repository for the three categories that are easy to lose during refactoring: COPR repositories, stand-alone remote RPM files, and Flatpak applications.

## COPR repositories

The role contains all 12 COPR definitions from the source repository and enables them through `community.general.copr` when `fedora_workstation_enable_copr_repositories: true`. The catalog includes bottom, choose, gping, lazydocker, starship, yumex-ng, password-store, lazygit, onefetch, rubygem-taskjuggler, Command Line Assistant, and dnf-ui.

## Stand-alone RPM packages

All 25 unique remote RPM URLs from the source repository are retained in `fedora_workstation_remote_rpm_catalog`. The original source contains 27 entries because the Proton Mail desktop RPM occurs three times. Stable/latest URLs are enabled by default; version-pinned and Fedora-version-pinned URLs are retained with `enabled: false` until they are explicitly reviewed for compatibility. Additional URLs can be placed in `fedora_workstation_remote_rpms`.

## Flatpak applications

The complete source Flatpak catalog is retained. Duplicate `org.shotcut.Shotcut` was de-duplicated. The source aliases `krita` and `kdenline` are normalized to `org.kde.krita` and `org.kde.kdenlive`. `com.microsoft.Teams.flatpakref`, `krita`, and `kdenline` are also retained under `fedora_workstation_flatpak_legacy_source_ids` for audit/migration purposes rather than being passed as current application IDs.
