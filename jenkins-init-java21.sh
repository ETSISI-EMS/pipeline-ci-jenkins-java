#cloud-config
package_upgrade: true

runcmd:
  # Base tools
  - apt-get update
  - apt-get install -y ca-certificates curl gnupg wget

  # --- Install Java 21 (Temurin) from Adoptium APT repo ---
  - mkdir -p /etc/apt/keyrings
  - curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg
  - sh -c 'echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb $(awk -F= '\''/^VERSION_CODENAME/{print$2}'\'' /etc/os-release) main" > /etc/apt/sources.list.d/adoptium.list'
  - apt-get update
  - apt-get install -y temurin-21-jre

  # Set Java 21 as the default 'java' (so Jenkins uses it)
  - sh -c 'update-alternatives --set java "$(update-alternatives --list java | grep temurin-21 | head -n 1)"'

  # --- Jenkins repo (key 2026) + install ---
  - wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
  - sh -c 'echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list'
  - apt-get update
  - apt-get install -y jenkins

  # Force Jenkins to use Java 21 explicitly (belt-and-suspenders)
  - sh -c 'JAVA_BIN="$(readlink -f "$(command -v java)")"; JAVA_HOME_DIR="$(dirname "$(dirname "$JAVA_BIN")")"; echo "JAVA_HOME=$JAVA_HOME_DIR" >> /etc/default/jenkins'

  # Start Jenkins
  - systemctl enable --now jenkins