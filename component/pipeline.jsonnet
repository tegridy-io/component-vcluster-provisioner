// main template for efk-provisioning
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();

// The hiera parameters for the component
local params = inv.parameters.vcluster_provisioner;

local pipeline = {
  stages: [
    'diff',
    'apply',
  ],
  variables: {
    K8S_API_URL: '${K8S_API_URL}',
    K8S_TOKEN: '${K8S_TOKEN}',
    PATH_MANIFESTS: 'manifests/vcluster-provisioner/10_helmchart.yaml',
    PATH_ROUTE: 'manifests/vcluster-provisioner/10_route.yaml',
  },
  '.openshift': {
    image: '%(registry)s/%(repository)s:%(tag)s' % params.images.kubectl,
    before_script: [
      'oc login --server=${K8S_API_URL} --token=${K8S_TOKEN}',
    ],
  },
  diff: {
    stage: 'diff',
    extends: [
      '.openshift',
    ],
    script: [
      'kubectl diff -f ${PATH_MANIFESTS} || [ $? -eq 1 ]',
    ] + if params.infrastructure.type == 'openshift' then [ 'kubectl diff -f ${PATH_ROUTE} || [ $? -eq 1 ]' ] else [],
    only: [
      'master',
    ],
  },
  apply: {
    stage: 'apply',
    extends: [
      '.openshift',
    ],
    script: [
      'kubectl apply -f ${PATH_MANIFESTS}',
    ] + if params.infrastructure.type == 'openshift' then [ 'kubectl apply -f ${PATH_ROUTE}' ] else [],
    when: 'manual',
    only: [
      'master',
    ],
  },
};

// Define outputs below
{
  'gitlab-ci': pipeline,
}
