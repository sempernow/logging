##############################################################################
## Makefile.settings : Environment Variables for Makefile(s)
include Makefile.settings
# … ⋮ ︙ • ● – — ™ ® © ± ° ¹ ² ³ ¼ ½ ¾ ÷ × ₽ € ¥ £ ¢ ¤ ♻ ⚐ ⚑ ✪ ❤  \ufe0f
# ☢ ☣ ☠ ¦ ¶ § † ‡ ß µ Ø ƒ Δ ☡ ☈ ☧ ☩ ✚ ☨ ☦ ☓ ♰ ♱ ✖  ☘  웃 𝐀𝐏𝐏 🡸 🡺 ➔
# ℹ️ ⚠️ ✅ ⌛ 🚀 🚧 🛠️ 🔧 🔍 🧪 👈 ⚡ ❌ 💡 🔒 📊 📈 🧩 📦 🥇 ✨️ 🔚
##############################################################################
## Environment variable rules:
## - Any TRAILING whitespace KILLS its variable value and may break recipes.
## - ESCAPE only that required by the shell (bash).
## - Environment hierarchy:
##   - Makefile environment OVERRIDEs OS environment lest set using `?=`.
##     - `FOO ?= bar` is overridden by parent setting; `export FOO=new`.
##     - `FOO :=`bar` is NOT overridden by parent setting.
##   - Docker YAML `env_file:` OVERRIDEs OS and Makefile environments.
##   - Docker YAML `environment:` OVERRIDEs YAML `env_file:`.
##   - CMD-inline OVERRIDEs ALL REGARDLESS; `make recipeX FOO=new BAR=new2`.


##############################################################################
## Recipes : Meta

menu :
	$(INFO) "🚧  Elasticsearch + Fluent* + Kibana"
	@echo "efk-apply      : Install EFK stack (requires per-app parsers)"
	@echo "efk-delete     : Teardown EFK stack"
	@echo "efk-verify     : GET request to Kibana"
	$(INFO) "🚧  Loki (Grafana)"
	@echo "loki-install   : Install Grafana Loki chart"
	@echo "loki-delete    : Uninstall Grafana Loki chart"
	$(INFO) "🚧  Elasticsearch + Vector + Kibana"
	@echo "vector-install : Install EVK  ✅  Zero per-app config"
	@echo "vector-status  : Check Vector logging stack status"
	@echo "vector-logs    : View Vector collector logs"
	@echo "vector-delete  : Uninstall Vector logging stack"
	$(INFO) "🔍  Inspect : Hosts"
	@echo "status       : Print targets' status"
	@echo "ausearch     : All recent denied"
	@echo "sealert      : sealert -l '*'"
	@echo "net          : Interfaces' info"
	@echo "vip          : Reveal vIP host by listing all IPv4 attached to ${HALB_DEVICE} of each host"
	@echo "link         : L2"
	@echo "route        : L3"
	@echo "ruleset      : nftables rulesets"
	@echo "iptables     : iptables"
	@echo "ipvs         : List the IPVS table"
	@echo "psk          : ps of K8s processes"
	@echo "psrss        : ps sorted by RSS usage"
	@echo "pscpu        : ps sorted by CPU usage"
	@echo "df           : df -hT"
	$(INFO) "🔍  Inspect : K8s API"
	@echo "journal      : kubelet logs … --since='${ADMIN_JOURNAL_SINCE}' (per node)"
	@echo "version      : GET /version"
	@echo "health       : GET /livez, /readyz"
	@echo "apiserver    : Timeout errors of K8s API server logs"
	@echo "events       : kubectl events -A --sort-by=.lastTimestamp |tail -n 50"
	@echo "info         : kubectl cluster-info"
	@echo "dump         : kubectl cluster-info dump |grep -i error"
	@echo "nodes        : K8s Node(s) status"
	@echo "pods         : kubectl get pods -A -o wide -w"
	@echo "podcidr      : PodCIDR and per node"
	@echo "certs-check  : kubeadm certs check-expiration"
	$(INFO) "🧪  Test"
	@echo "uniq         : K8s requires each node have a unique hostname, product ID, and network device MAC"
	@echo "iostat       : Disk I/O : See '*_await' (req/resp latency [ms]) and '%util'(ization)"
	@echo "fio          : etcd fsync 99-th percentile latency"
	@echo "iperf        : Network I/O : Pod Network Bandwidth test"
	@echo "bench        : ApacheBench (ab) load tests"
	@echo "  -health    : Load test K8s-API endpoint"
	@echo "  -e2e       : Load test Ingress-E2E-Test endpoint"
	$(INFO) "🛠️  Maintenance : Host"
	@echo "userrc       : Configure targets' bash shell (See https://${ADMIN_USER_CONF}.git)"
	@echo "reboot       : Reboot all (K8S_NODES) : ${K8S_NODES}"
	@echo "  -soft      : drain ➔  reboot ➔  uncordon"
	@echo "  -hard      : reboot ${K8S_NODES}"
	$(INFO) "🛠️  Maintenance : Meta"
	@echo "env          : Print the make environment"
	@echo "mode         : Fix folder and file modes of this project"
	@echo "eol          : Fix line endings : Convert all CRLF to LF"
	@echo "html         : Process all markdown (MD) to HTML"
	@echo "commit       : Commit and push this source"
	@echo "bundle       : Create ${PRJ_ROOT}.bundle"

env :
	$(INFO) 'Environment'
	@echo "PWD=${PRJ_ROOT}"
	@env |grep DOMAIN_ |grep -v HALB
	@echo
	@env |grep HALB_ |sort
	@echo
	@env |grep K8S_ |grep -v ADMIN |sort
	@echo
	@env |grep ADMIN_ |sort
	@env |grep ANSIBASH_ |sort

eol :
	find . -type f ! -path '*/.git/*' -exec dos2unix {} \+
mode :
	find . -type d ! -path './.git/*' -exec chmod 755 "{}" \;
	find . -type f ! -path './.git/*' -exec chmod 640 "{}" \;
#	find . -type f ! -path './.git/*' -iname '*.sh' -exec chmod 755 "{}" \;
tree :
	tree -d |tee tree-d
html :
	find . -type f ! -path './.git/*' -name '*.md' -exec md2html.exe "{}" \;
commit push : html mode
	gc && git push && gl && gs
bundle :
	git bundle create ${PRJ_ROOT}.bundle --all

##############################################################################
## Recipes : Logging : Cluster-level Logs : Log Aggregation

## EFK : Elasticsearch + Fluent-bit + Kibana
efk := elastic/efk-chatgpt/stack.sh
efk-apply :
	bash ${ADMIN_SRC_DIR}/${efk} apply
efk-forward :
	bash ${ADMIN_SRC_DIR}/${efk} forward
efk-delete :
	bash ${ADMIN_SRC_DIR}/${efk} delete
efk-verify :
	bash ${ADMIN_SRC_DIR}/${efk} verify

## Loki : Loki (Grafana)
loki := loki/stack.sh
loki-install :
	bash ${ADMIN_SRC_DIR}/${loki} upgrade
loki-delete :
	bash ${ADMIN_SRC_DIR}/${loki} uninstall

## Vector : EVK
vector := vector/evk-complete.yaml
vector-install vector-apply :
	$(INFO) 'Installing Elasticsearch + Vector + Kibana logging stack'
	kubectl apply -f ${ADMIN_SRC_DIR}/${vector}
	@echo "Waiting for Elasticsearch to be ready (may take 2-3 minutes)..."
	kubectl wait --for=condition=ready pod -l app=elasticsearch -n logging --timeout=300s || true
	@echo "Waiting for Kibana to be ready..."
	kubectl wait --for=condition=ready pod -l app=kibana -n logging --timeout=300s || true
	@echo "Waiting for Vector DaemonSet to be ready..."
	kubectl rollout status daemonset/vector -n logging --timeout=180s || true
	$(INFO) 'Vector logging stack deployed successfully'
	@echo "Kibana available at: http://NODE_IP:30561"
	@echo "See logging/vector/DEPLOY-VECTOR.md for setup instructions"
vector-status :
	$(INFO) 'Vector logging stack status'
	kubectl get pods,svc -n logging
	@echo ""
	@echo "Elasticsearch indices:"
	kubectl exec -n logging elasticsearch-0 -- curl -s 'http://localhost:9200/_cat/indices?v' 2>/dev/null || echo "Elasticsearch not ready yet"
vector-logs :
	$(INFO) 'Recent Vector logs'
	kubectl logs -n logging daemonset/vector --tail=100
vector-delete vector-uninstall :
	$(INFO) 'Removing Vector logging stack'
	kubectl delete -f ${ADMIN_SRC_DIR}/${vector} || true
	kubectl delete pvc -n logging --all || true
	$(INFO) 'Vector logging stack removed'

status hello :
	@ansibash 'printf "%12s: %s\n" SELinux $$(getenforce) \
	    && printf "%12s: %s\n" firewalld $$(systemctl is-active firewalld.service) \
	    && printf "%12s: %s\n" haproxy $$(systemctl is-active haproxy) \
	    && printf "%12s: %s\n" keepalived $$(systemctl is-active keepalived) \
	    && printf "%12s: %s\n" containerd $$(systemctl is-active containerd) \
	    && printf "%12s: %s\n" kubelet $$(systemctl is-active kubelet) \
	    && printf "%12s: %s\n" Kernel $$(uname -r) \
	    && printf "%12s:%s\n" uptime "$$(uptime)" \
	'


##############################################################################
## Recipes : Cluster

psrss :
	ansibash psrss
pscpu :
	ansibash pscpu

# Configure bash shell of target hosts using the declared Git project
userrc :
	ansibash 'git clone https://github.com/sempernow/userrc 2>/dev/null || echo ok'
	ansibash 'pushd userrc && git pull && make sync-user && make user && echo ✅ Updated!'

journal journald journalctl :
	ansibash "sudo journalctl --no-pager -u kubelet --since='${ADMIN_JOURNAL_SINCE}' |grep -i error"
version :
	type jq >/dev/null 2>&1 \
	    && curl -fksS https://${K8S_FQDN}:8443/version |jq . \
	    || curl -fksS https://${K8S_CONTROL_ENTRYPOINT}/version \
	    || echo "ERR : $$?"
health ready healthz readyz :
	@bash make.recipes.sh health
events :
	kubectl get events -A --sort-by=.lastTimestamp |tail -n 50

psk :
	ansibash psk
pods pod watch :
	kubectl get pod -A -o wide -w
nodes node :
	@kubectl get node && echo
	@type yq >/dev/null 2>&1 \
	    && kubectl get node -o yaml \
	        |yq '.items[]? | [{"name": .metadata.name, "trueConditions": (.status.conditions[] | select(.status == "True")), "nodeInfo": .status.nodeInfo}]' \
	            || echo REQUIREs yq
apiserver :
	@echo "ℹ️  Timeouts at all K8s API Pods (kube-apiserver) since ${ADMIN_K8S_LOG_SINCE} (ADMIN_K8S_LOG_SINCE)"
	@printf "%s\n" ${K8S_NODES} |xargs -I{} kubectl -n kube-system logs pod/kube-apiserver-{} --timestamps --since=${ADMIN_K8S_LOG_SINCE} \
	    |grep -e timeout -e time-elapsed || echo "    … NONE logged."

bench : bench-health bench-e2e
bench-health :
	@echo -e "\n📊  K8s API"
	type -t ab && ab -c 100 -n 10000 https://${K8S_CONTROL_ENTRYPOINT}/readyz?verbose || echo "⚠️  REQUIREs ab"

info :
	kubectl cluster-info


