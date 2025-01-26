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

// Define outputs below
{
  '00_namespace': namespace,
}
