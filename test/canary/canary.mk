
# Installs Istio 1.2 using default install yaml, install canary, verify canary starts.
test-inplace: run-build-canary
	kubectl apply -k kustomize/istio-1.2/default --prune -l release=istio
	kubectl apply -k kustomize/istio-canary --prune -l release=istio-canary
	kubectl wait deployments istio-pilotcanary -n ${ISTIO_SYSTEM_NS} --for=condition=available --timeout=${WAIT_TIMEOUT}
	$(MAKE) test-inplace-tests

test-inplace-tests:
	# Manual injection test for canary
	kubectl create ns fortio-canary || true
	kubectl label ns fortio-canary istio-injection=disabled --overwrite

	# Notice the use of a special mesh.yaml, to override the pilot address.
	# values and mesh are set to use TLS to pilot
	istioctl kube-inject -f test/inplace/fortio.yaml \
		-n fortio-canary \
		--meshConfigFile test/inplace/mesh.yaml \
		--valuesFile test/inplace/values.yaml \
		--injectConfigFile istio-control/istio-autoinject/files/injection-template.yaml \
	 | kubectl apply -n fortio-canary -f -

	 kubectl wait deployments fortio -n fortio-canary --for=condition=available --timeout=${WAIT_TIMEOUT}


	kubectl create ns fortio-canary-inject || true
	kubectl label ns fortio-canary-inject istio-injection=enabled --overwrite
	kubectl apply -n fortio-canary-inject -f test/inplace/fortio-cli.yaml
	kubectl wait deployments cli-fortio -n fortio-canary-inject --for=condition=available --timeout=${WAIT_TIMEOUT}

