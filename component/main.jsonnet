// main template for vcluster-provisioner
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.vcluster_provisioner;

local namespace = kube.Namespace(params.infrastructure.namespace.name) {
  metadata+: {
    annotations: {
      'argocd.argoproj.io/sync-wave': '-10',
    } + com.makeMergeable(params.infrastructure.namespace.annotations),
    labels: {
      'app.kubernetes.io/name': params.infrastructure.namespace.name,
    } + com.makeMergeable(params.infrastructure.namespace.labels),
    name: params.infrastructure.namespace.name,
  },
};

local route = {
  apiVersion: 'route.openshift.io/v1',
  kind: 'Route',
  metadata: {
    name: params._clusterName,
    namespace: params.infrastructure.namespace.name,
  },
  spec: {
    host: params.ingress.host,
    port: {
      targetPort: 'https',
    },
    tls: {
      termination: 'passthrough',
    },
    to: {
      kind: 'Service',
      name: params._clusterName,
      weight: 100,
    },
    wildcardPolicy: 'None',
  },
};

// Define outputs below
{
  '00_namespace': namespace,
  [if params.infrastructure.type == 'openshift' then '10_route']: route,
}
