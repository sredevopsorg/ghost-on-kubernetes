<body style="background:#000;color:#fff;">

<h1 id="ghost-on-kubernetes-by-sredevopsorg">Ghost on Kubernetes by SREDevOps.Org</h1>
<center><a href="https://sredevops.org" target="_blank" rel="noopener noreferrer"><img src="https://github.com/sredevopsorg/.github/assets/34670018/6878e00f-635c-4553-8df7-3b20406fdb4f" alt="SREDevOps.org" width="60%" align="center" /></a></center>

<p><strong>Community for SRE, DevOps, Cloud Native, GNU/Linux, and more. 🌎</strong></p>
<p><a href="https://github.com/sredevopsorg/ghost-on-kubernetes/actions/workflows/multi-build.yaml"><img src="https://github.com/sredevopsorg/ghost-on-kubernetes/actions/workflows/multi-build.yaml/badge.svg?branch=main" alt="Build Multiarch"></a> | <a href="https://github.com/sredevopsorg/ghost-on-kubernetes/pkgs/container/ghost-on-kubernetes"><img src="https://ghcr-badge.egpl.dev/sredevopsorg/ghost-on-kubernetes/size?color=%2344cc11&tag=main&label=main+image+size" alt="Image Size"></a> | <a href="https://securityscorecards.dev/viewer/?uri=github.com/sredevopsorg/ghost-on-kubernetes"><img src="https://api.securityscorecards.dev/projects/github.com/sredevopsorg/ghost-on-kubernetes/badge" alt="OpenSSF Scorecard"></a> | <img src="https://img.shields.io/github/forks/sredevopsorg/ghost-on-kubernetes?style=social" alt="Fork this repository"> | <img src="https://img.shields.io/github/stars/sredevopsorg/ghost-on-kubernetes?style=social" alt="Star this repository"> | <a href="https://www.bestpractices.dev/projects/8888"><img src="https://www.bestpractices.dev/projects/8888/badge" alt="OpenSSF Best Practices"></a></p>
<blockquote>
<p>This repository implements Ghost CMS v5.xx.x from <a href="https://github.com/TryGhost/Ghost">TryGhost (upstream)</a> on Kubernetes, with our custom image, which has significant improvements to be used on Kubernetes. See this whole README for more information.</p>
</blockquote>
<h2 id="recent-changes">Recent Changes</h2>
<h3 id="weve-made-some-significant-updates-to-improve-the-security-and-efficiency-of-our-ghost-implementation-on-kubernetes">We&#39;ve made some significant updates to improve the security and efficiency of our Ghost implementation on Kubernetes</h3>
<ol start="0">
<li><p><strong>Multi-arch support</strong>: The images are now multi-arch, with <a href="#arm64-compatible">support for amd64 and arm64</a>.</p>
</li>
<li><p><strong>Distroless Image</strong>: We use <a href="https://github.com/GoogleContainerTools">@GoogleContainerTools</a>&#39;s <a href="https://github.com/GoogleContainerTools/distroless/blob/main/examples/nodejs/Dockerfile">Distroless NodeJS</a> as execution environment for the final image. Distroless images are minimal images that contain only the necessary components to run the application, making them more secure and efficient than traditional images.</p>
</li>
<li><p><strong>MySQL StatefulSet</strong>: We&#39;ve changed the MySQL implementation to a StatefulSet. This provides stable network identifiers and persistent storage, which is important for databases like MySQL that need to maintain state.</p>
</li>
<li><p><strong>Init Container</strong>: We&#39;ve added an init container to the Ghost deployment. This container is responsible for setting up the necessary configuration files and directories before the main Ghost container starts, ensuring the right directories are created, correct ownership for user node inside distroless container UID/GID to 1000:1000, and recreate public folder on every start so the assets are always up to date. Check <a href="./deploy/06-ghost-deployment.yaml">deploy/06-ghost-deployment.yaml</a> for details on these changes.</p>
</li>
<li><p><strong>Entrypoint Script</strong>: We&#39;ve introduced a new entrypoint script that runs as the non-privileged user inside the distroless container. This script is responsible for updating the default theme and starting the Ghost application. This script is executed by the Node user without privileges within the Distroless container, which updates default themes and starts the Ghost application, operation which is performed into the distroless container itself.</p>
</li>
</ol>
<h2 id="features">Features</h2>
<ul>
<li><a href="#arm64-compatible">ARM64 Support!</a></li>
<li>We use the official Node 20 Iron Bookworm image as our build environment. <a href="./Dockerfile">Dockerfile</a></li>
<li>We introduce a multi-stage build process to compile the image.</li>
<li><a href="https://github.com/GoogleContainerTools/distroless/blob/main/README.md">Distroless Node 20 Debian 12</a> as our runtime environment for the final image.</li>
<li>We removed gosu, using the default Node user (UID 1000:GID 1000) inside the Distroless container.</li>
<li>New Entrypoint flow, using a Node.js script executed by the Node user without privileges within the Distroless container, which updates default themes and starts the Ghost application, operation which is performed into the distroless container itself.</li>
<li>We use the latest version of Ghost 5 (when the image is built).</li>
</ul>
<h2 id="arm64-compatible">ARM64 Compatible</h2>
<ul>
<li>Images are now multi-arch, with support for amd64 and arm64 <a href="https://github.com/sredevopsorg/ghost-on-kubernetes/issues/73#issuecomment-1933939315">(link to discussion)</a></li>
</ul>
<h2 id="star-history">Star History</h2>
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=sredevopsorg/ghost-on-kubernetes&type=Date&theme=dark" />
  <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=sredevopsorg/ghost-on-kubernetes&type=Date" />
  <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=sredevopsorg/ghost-on-kubernetes&type=Date" height="300px" />
</picture>

<h2 id="installation">Installation</h2>
<h3 id="0-clone-the-repository-or-fork-it">0. Clone the repository or fork it</h3>
<pre><code class="language-bash"># Clone the repository
git clone https://github.com/sredevopsorg/ghost-on-kubernetes.git --depth 1 --branch main --single-branch --no-tags
# Change directory
cd ghost-on-kubernetes
# Create a new branch for your changes (optional but recommended).
git checkout -b my-branch --no-track --detach
</code></pre>
<h3 id="1-check-the-example-configurations">1. Check the example configurations</h3>
<ul>
<li><p>There are some example configuration files in the <a href="./examples/">examples</a> directory. We use the stored configuration as a <code>kind: Secret</code> in the <code>ghost-k8s</code> namespace for Ghost and MySQL configuration. There are two example configuration files:</p>
<ul>
<li><p><code>config.development.sample.yaml</code>: This configuration file is for the Ghost development environment. It uses SQLite as the database. It can be useful if you want to test the Ghost configuration before implementing it in a production environment.</p>
</li>
<li><p><code>config.production.sample.yaml</code>: This configuration file is for the Ghost production environment. It uses MySQL 8, and is the recommended configuration for production environments. It requires a valid top-level domain (TLD) and <a href="./deploy/07-ingress.yaml">configuration for Ingress to access Ghost from the Internet</a>.</p>
</li>
</ul>
</li>
<li><p>If you need more information on the configuration, check the <a href="https://ghost.org/docs/config/#custom-configuration-files">official Ghost documentation</a>.</p>
</li>
</ul>
<h3 id="2-review-the-default-values-and-make-changes-as-needed-in-the-following-files">2. Review the default values and make changes as needed in the following files</h3>
<ul>
<li><p>deploy/00-namespace.yaml # Change the namespace according to your needs</p>
</li>
<li><p>deploy/01-secrets.yaml</p>
</li>
</ul>
<pre><code class="language-yaml"># deploy/01-secrets.yaml

apiVersion: v1
kind: Secret
metadata:
  name: mysql-ghost-k8s
  namespace: ghost-k8s
type: Opaque
stringData:
  MYSQL_DATABASE: mysql-db-name # Same as in deploy/04-config.production.yaml
  MYSQL_USER: mysql-db-user # Same as in deploy/04-config.production.yaml
  MYSQL_PASSWORD: mysql-db-password # Same as in deploy/04-config.production.yaml
  MYSQL_ROOT_PASSWORD: mysql-db-root-password # Same as in deploy/04-config.production.yaml
</code></pre>
<ul>
<li>deploy/02-pvc.yaml # Change the storageClassName according to your needs</li>
<li>deploy/03-services.yaml # Change the hosts according to your needs</li>
<li>deploy/04-config.production.yaml # Change the values according to the secrets and services</li>
<li>deploy/05-mysql.yaml # Change the values according to the secrets and services</li>
<li>deploy/06-ghost-deployment.yaml # Change the values according to the secrets and services</li>
<li>deploy/07-ingress.yaml # Optional</li>
</ul>
<h3 id="3-apply-your-manifests">3. Apply your manifests</h3>
<pre><code class="language-bash"># Before applying the manifests, make sure you are in the root directory of the repository
# 🚨 Be sure to not change the filenames, also be sure to modify the files according to your needs before applying them.
# Why? Just because we need to deploy them in order. If you change the filenames, you will need to apply them one by one in the correct order.
kubectl apply -f ./deploy
</code></pre>
<h3 id="4-access-your-ghost-cms">4. Access your Ghost CMS</h3>
<pre><code class="language-bash"># Get the ingress IP, if you have configured the Ingress
kubectl get ingress -n ghost-k8s -o wide 

# Alternatively, create a port-forwarding rule to access the Ghost CMS
kubectl port-forward -n ghost-k8s service/service-ghost-k8s 2368:2368
</code></pre>
<h3 id="5-open-your-browser-and-access-your-ghost-cms">5. Open your browser and access your Ghost CMS</h3>
<ul>
<li><p><a href="http://localhost:2368">http://localhost:2368</a> (if you used the port-forwarding method)</p>
</li>
<li><p><a href="http://your-ghost-domain.com">http://your-ghost-domain.com</a> (if you used the Ingress method)</p>
</li>
</ul>
<h3 id="6-log-in-to-your-ghost-cms">6. Log in to your Ghost CMS</h3>
<ul>
<li><p><a href="http://localhost:2368/ghost">http://localhost:2368/ghost</a> (if you used the port-forwarding method)</p>
</li>
<li><p><a href="http://your-ghost-domain.com/ghost">http://your-ghost-domain.com/ghost</a> (if you used the Ingress method)</p>
</li>
</ul>
<h2 id="contributing">Contributing</h2>
<p>We welcome contributions from the community! Please check the <a href="./CONTRIBUTING.md">CONTRIBUTING.md</a> file for more information on how to contribute to this project.</p>
<h2 id="license-and-credits">License and Credits</h2>
<ul>
<li>This project is licensed under the GNU General Public License v3.0. Please check the <a href="./LICENSE">LICENSE</a> file for more information.</li>
<li>The Ghost CMS is licensed under the <a href="https://github.com/TryGhost/Ghost/blob/main/LICENSE">MIT License</a>.</li>
<li>The node:20 image and the Distroless image are licensed by their respective owners.</body></li>
</ul>
