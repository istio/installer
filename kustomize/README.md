# Kustomize support

Organization: each directory corresponds to a a-la-carte component or a set of components ('profile').

Inside there is a "kustomization.yaml" file, some patches or other source files, and one generated 
file - currently matching the name of the directory ( ex. istio-ingress/istio-ingress.yaml). 

TODO: use a gen- prefix for generated yaml files.

** The number of possible options and settings is restricted to what kustomize supports.  Many of Istio 
values.yaml configurations that are reflected into CLI or config maps are difficult to support in kustomize **

# User experience

Basic install:
```bash
kubectl apply --prune -l a=b github.com/istio/install/kustomize/NAME

```

Local kustomizations: create a local kustomize.yaml file, with any patches and changes supported by kustomize:

```yaml


```

# Components (a-la-carte)

Each 'a-la-carte' profile deploys one istio microservice. Intended for advanced users who want 
to install istio with full control, and for 'operator'.

## cluster

Contains cluster-wide resources - cluster roles, istio-system namespace, service accounts, bindings.
It includes no deployments or services.

Must be installed first.

Required unless istio-1.2 or later installed with the old installer is already present. 

IMPORTANT: in upgrade cases you can't simply remove the previous version of istio, since this would delete
cluster-wide resources. The proper way is to disable the deployments ( in progress )

## citadel

Should be installed after the cluster resources, and before all other components. 

Operator should wait for service account secrets to be created before installing the next component.  

## sds-agent

Optional, creates a DaemonSet that enables node SDS. 

## istio-ingress

Ingress.

## pilot

Installs istio-pilot.  

## autoinject

Install an opt-in auto-injector, enabled by using a namespace label

```yaml
  labels:
    istio-env: istio-system-default
```


## cluster-autoinject

Installs a global auto-injector. User can opt-out:

```yaml
  labels:
    istio-injection: disabled
```

or select a specific 'opt-in' profile:

```yaml
  labels:
    istio-env: istio-system-default
```

# Profiles 

Profiles install sets of components.

## demo

Equivalent with the demo from 1.2. Almost all components installed. 

## micro

Installs only Pilot and Ingress. Should only be used on secure networks (IPSec or other security provided 
by the CNI), since it doesn't include Citadel or mtls support. 

## istio-canary

Installs a canary version of pilot and injector, alongside an existing 1.2 or 1.3 "old installer" istio.


# Implementation

"helm template" will be used with the normal values/global/user settings, and generate a file under 
$OUT/$NAMESPACE/$COMPONENT

If the kustomize file exists, it will be applied before running "kubectl apply --prune".

# Dependencies

This requires v1.14 version of kubectl, or the matching kustomize version (2.0.3).

