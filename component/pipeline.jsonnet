// main template for efk-provisioning
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();

// The hiera parameters for the component
local params = inv.parameters.vcluster_provisioner;
local manifestsHelm = 'manifests/vcluster-provisioner/10_helmchart.yaml';

local pipeline = {
  stages: [
    'diff',
    'apply',
  ],
  variables: {
    K8S_API_URL: '${K8S_API_URL}',
    K8S_TOKEN: '${K8S_TOKEN}',
    MANIFESTS_PATH: manifestsHelm,
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
      'kubectl diff -f ${MANIFESTS_PATH} || [ $? -eq 1 ]',
    ],
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
      'kubectl apply -f ${MANIFESTS_PATH}',
    ],
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
