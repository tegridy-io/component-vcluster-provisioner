local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();

// The hiera parameters for the component
local params = inv.parameters.vcluster_provisioner;
local overrides = params.helmValues.vcluster;

// Values Files
local component = com.makeMergeable({
  controlPlane: {
    distro: {
      // k8s: {
      //   apiServer: {
      //     image: params.images.kube_apiserver,
      //   },
      //   controllerManager: {
      //     image: params.images.kube_controller_manager,
      //   },
      //   scheduler: {
      //     image: params.images.kube_scheduler,
      //   },
      // },
      k3s: {
        enabled: params.components.k3s.enabled,
        image: params.images.k3s,
        imagePullPolicy: 'IfNotPresent',
        resources: {
          limits: {
            cpu: null,
            memory: '256Mi',
          },
          requests: {
            cpu: '10m',
            memory: '64Mi',
          },
        } + com.makeMergeable(params.components.k3s.resources),
      },
      // k0s: {
      //   image: params.images.k0s,
      // }
    },
    statefulSet: {
      image: params.images.vcluster,
      imagePullPolicy: 'IfNotPresent',
      resources: {
        requests: {
          'ephemeral-storage': null,
          cpu: '50m',
          memory: '512Mi',
        },
        limits: {
          'ephemeral-storage': null,
          memory: '2Gi',
        },
      } + com.makeMergeable(params.components.vcluster.resources),
      persistence: {
        volumeClaim: {
          enabled: true,
          retentionPolicy: 'Retain',
          size: params.components.vcluster.storageSize,
          storageClass: params.components.vcluster.storageClass,
        },
      },
      security: {
        containerSecurityContext: {
          runAsUser: null,
          runAsGroup: null,
        },
      },
    },
  },
  exportKubeConfig: {
    server: '',
  },
  rbac: {
    role: {
      enabled: true,
      overwriteRules: [
        {
          apiGroups: [ '' ],
          resources: [ 'configmaps', 'secrets', 'services', 'pods', 'pods/attach', 'pods/portforward', 'pods/exec', 'persistentvolumeclaims' ],
          verbs: [ 'create', 'delete', 'patch', 'update', 'get', 'list', 'watch' ],
        },
        {
          apiGroups: [ 'apps' ],
          resources: [ 'statefulsets', 'replicasets', 'deployments' ],
          verbs: [ 'get', 'list', 'watch' ],
        },
        {
          apiGroups: [ '' ],
          resources: [ 'endpoints' ],
          verbs: [ 'create', 'delete', 'patch', 'update' ],
        },
        {
          apiGroups: [ '' ],
          resources: [ 'endpoints', 'events', 'pods/log' ],
          verbs: [ 'get', 'list', 'watch' ],
        },
        {
          apiGroups: [ 'networking.k8s.io' ],
          resources: [ 'ingresses' ],
          verbs: [ 'create', 'delete', 'patch', 'update', 'get', 'list', 'watch' ],
        },
      ],
    },
  },
  sync: {
    toHost: {
      endpoints: {
        enabled: true,
      },
      ingresses: {
        enabled: true,
      },
    },
  } + com.makeMergeable(params.sync),
  telemetry: {
    enabled: false,
  },
});

{
  'helm-component': component,
  'helm-overrides': overrides,
}
