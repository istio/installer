
run-v2-template:
	${IOP} istio-system pilot13 istio-control/istio-discovery -t \
		--set clusterResources=false \
		--set version=v13canary

run-install-v13canary:
    # Initial try without validation
	${IOP} istio-system galley13 istio-control/istio-config \
		--set clusterResources=false \
		--set version=v13canary \
		--set global.configValidation=false \

	${IOP} istio-system pilot13 istio-control/istio-discovery \
		--set clusterResources=false \
		--set version=v13canary

run-install-v12-nopilot:
	helm template --name=istio --namespace=istio-system \
	  --set global.hub=istio --set global.tag=1.2.1 \
	  ../istio/install/kubernetes/helm/istio | kubectl apply --prune -l release=istio -f -
