

# Target to run SDS graceful upgrade tests
test-sds:
	$(MAKE) maybe-clean maybe-prepare sync
	$(MAKE) kind-run TARGET="run-sds-tests"

# Will install basic Istio, and in a separate ns the SDS-enabled control plane and test app
run-sds-tests: install-crds install-base install-sds-cp install-sds-app

# Not working with kind default setup: --set global.sds.useTrustworthyJwt=true
#

# The test is generating an injector with self-signed certificate - this will not work with kustomize (helm generates
# a cert).
# TODO: investigate if kustomize can do the same

# Test for installation of the test-mode SDS and test app.
install-sds-cp: run-build-multi
	bin/iop istio-system istio-citadel ${BASE}/security/citadel  ${IOP_OPTS}  ${INSTALL_OPTS} \
	  --set global.sds.enabled=true
	# SDS agent runs in istio-system, next to citadel. Both are security-critical.
	kubectl apply -k kustomize/sds-agent
	# Equivalent with:
	# bin/iop istio-system istio-sds-agent ${BASE}/security/nodeagent ${IOP_OPTS}  ${INSTALL_OPTS}

	kubectl create ns istio-sds || true
	kubectl label ns istio-sds istio-injection=disabled --overwrite

	bin/iop istio-sds istio-discovery ${BASE}/istio-control/istio-discovery  ${IOP_OPTS}  ${INSTALL_OPTS} \
	  --set pilot.useMCP=false \
	  --set global.sds.enabled=true

	bin/iop istio-sds istio-autoinject ${BASE}/istio-control/istio-autoinject ${IOP_OPTS} ${INSTALL_OPTS} \
		 --set global.sds.enabled=true \
		 --set sidecarInjectorWebhook.selfSigned=true \
		 --set global.istioNamespace=istio-sds

	kubectl wait deployments istio-pilot istio-sidecar-injector -n istio-sds --for=condition=available --timeout=${WAIT_TIMEOUT}

install-sds-app:
	kubectl create ns fortio-sds || true
	kubectl label ns fortio-sds istio-env=istio-sds --overwrite
	kubectl -n fortio-sds apply -k test/sds
	kubectl wait deployments fortio  -n fortio-sds --for=condition=available --timeout=${WAIT_TIMEOUT}
	# TODO: curl to verify fortio works and check sds stats

# small tests for SDS config options - mainly checks the templates render with common sds-related
# options.
sds-unit:
	# Minimal - no MCP, use default k8s tokens
	${IOP} istio-sds istio-discovery ${BASE}/istio-control/istio-discovery -t \
	   --set pilot.useMCP=false --set global.sds.enabled=true  > ${TMPDIR}/pilot-sds1.yaml

	# Use MCP, new tokens, override trustDomain
	${IOP} istio-sds istio-discovery ${BASE}/istio-control/istio-discovery -t \
	   --set global.sds.enabled=true \
	   --set global.sds.useTrustworthyJwt=true \
	   --set global.trustDomain=example.com \
	    > ${TMPDIR}/pilot-sds-jwt-trustdomain.yaml

	# Verify manual inject works
	istioctl kube-inject -f test/sds/fortio.yaml -n fortio-sds --meshConfigFile test/simple/mesh.yaml \
	  --valuesFile test/simple/values.yaml \
      --injectConfigFile istio-control/istio-autoinject/files/injection-template.yaml >  ${TMPDIR}/fortio-injected.yaml

# SDS tests use telemetry lite.
# To visualize: use env.sh and 'kindFwd' helper to forward prom/grafana
install-sds-telemetry:
	$(MAKE) install-prometheus
	# TODO: add a small test to verify grafana has whatever we need to add. Right now it's empty of SDS info, which is a bug
	$(MAKE) install-grafana

sds-shell-app:
	$(MAKE) pod-shell NS=fortio-sds LABEL="app=fortio" C=istio-proxy CMD=bash

sds-shell-pilot:
	$(MAKE) pod-shell NS=istio-sds LABEL="istio=pilot" C=istio-proxy CMD=bash

sds-logs-pilot:
	$(MAKE) pod-logs NS=istio-sds LABEL="istio=pilot" C=discovery

sds-logs-pilotenvoy:
	$(MAKE) pod-logs NS=istio-sds LABEL="istio=pilot" C=istio-proxy

sds-kill:
	$(MAKE) pod-kill NS=fortio-sds LABEL="app=fortio"

sds-logs-app:
	$(MAKE) pod-logs NS=fortio-sds LABEL="app=fortio" C=istio-proxy

sds-logs-agent:
	$(MAKE) pod-logs NS=istio-system LABEL="app=istio-nodeagent" C=nodeagent

sds-dump:
	$(MAKE) pod-shell NS=fortio-sds LABEL="app=fortio" C=istio-proxy CMD="curl localhost:15000/certs"
	$(MAKE) pod-shell NS=fortio-sds LABEL="app=fortio" C=istio-proxy CMD="curl localhost:15000/config_dump"
    #"curl localhost:15000/logging?http2=trace -X POST"

# Generic debug target to exec into one of the containers, using LABEL, NS, C, CMD
pod-shell:
	kubectl -n ${NS} exec -it ${shell kubectl --namespace=${NS} get -l ${LABEL} pod -o=jsonpath='{.items[0].metadata.name}'} -c ${C} -- ${CMD}

pod-kill:
	kubectl -n ${NS} delete pod ${shell kubectl --namespace=${NS} get -l ${LABEL} pod -o=jsonpath='{.items[0].metadata.name}'}

pod-logs:
	kubectl -n ${NS} logs ${shell kubectl --namespace=${NS} get -l ${LABEL} pod -o=jsonpath='{.items[0].metadata.name}'} -c ${C} -f

