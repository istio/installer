
# Installs Istio 1.2 using default install yaml, install canary, verify canary starts.
test-inplace:
	kubectl apply -k kustomize/istio-1.2/default --prune -l release=istio
	kubectl apply -k kustomize/istio-canary --prune -l release=istio-canary
	kubectl wait deployments istio-pilot-canary istio-galley-canary istio-sidecar-injector-canary -n ${ISTIO_SYSTEM_NS} --for=condition=available --timeout=${WAIT_TIMEOUT}

