run-sds-tests: install-crds install-base

SDS_NS=istio-sds

install-sds-cp:
	kubectl create ns ${SDS_NS} || true
	kubectl label ns ${SDS_NS} istio-injection=disabled --overwrite
	bin/iop ${SDS_NS} istio-discovery ${BASE}/istio-control/istio-discovery ${IOP_OPTS}  ${INSTALL_OPTS}
	bin/iop ${SDS_NS} istio-sds-agent ${BASE}/security/nodeagent ${IOP_OPTS}  ${INSTALL_OPTS}
	bin/iop ${SDS_NS} istio-autoinject ${BASE}/istio-control/istio-autoinject \
		 ${IOP_OPTS} ${INSTALL_OPTS}
	kubectl wait deployments istio-discovery istio-sidecar-injector -n ${SDS_NS} --for=condition=available --timeout=${WAIT_TIMEOUT}

install-sds-app:
	kubectl create ns fortio-sds || true
	kubectl label ns fortio-sds istio-env=${SDS_NS} --overwrite
	kubectl -n fortio-sds apply -k test/fortio
	# TODO: wait and curl to verify fortio works and check sds stats
