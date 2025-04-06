local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();

// The hiera parameters for the component
local params = inv.parameters.vcluster_provisioner;
local overrides = params.helmValues.vcluster;
local distribution =
  if params.distribution.type == 'k3s' then 'k3s'
  else if params.distribution.type == 'k8s' then 'k8s'
  else if params.distribution.type == 'k0s' then 'k0s'
  else error 'Unsupported distribution type: ' + params.distribution.type;

// Values Files
local component = com.makeMergeable({
  controlPlane: {
    distro: {
      k8s: {
        enabled: if distribution == 'k8s' then true else false,
        apiServer: {
          image: params.images.kube_apiserver,
          imagePullPolicy: 'IfNotPresent',
        },
        controllerManager: {
          image: params.images.kube_controller_manager,
          imagePullPolicy: 'IfNotPresent',
        },
        scheduler: {
          image: params.images.kube_scheduler,
          imagePullPolicy: 'IfNotPresent',
        },
        resources: {
          limits: {
            cpu: null,
            memory: '256Mi',
          },
          requests: {
            cpu: '50m',
            memory: '64Mi',
          },
        } + com.makeMergeable(params.distribution.resources),
      },
      k3s: {
        enabled: if distribution == 'k3s' then true else false,
        image: params.images.k3s,
        imagePullPolicy: 'IfNotPresent',
        resources: {
          limits: {
            cpu: null,
            memory: '256Mi',
          },
          requests: {
            cpu: '50m',
            memory: '64Mi',
          },
        } + com.makeMergeable(params.distribution.resources),
      },
      k0s: {
        enabled: if distribution == 'k0s' then true else false,
        image: params.images.k0s,
        imagePullPolicy: 'IfNotPresent',
        resources: {
          limits: {
            cpu: null,
            memory: '256Mi',
          },
          requests: {
            cpu: '50m',
            memory: '64Mi',
          },
        } + com.makeMergeable(params.distribution.resources),
      },
    },
    ingress: {
      annotations: {
        'nginx.ingress.kubernetes.io/backend-protocol': 'HTTPS',
        'nginx.ingress.kubernetes.io/ssl-passthrough': 'true',
        'nginx.ingress.kubernetes.io/ssl-redirect': 'true',
      },
    } + com.makeMergeable(params.ingress),
    statefulSet: {
      image: params.images.vcluster,
      imagePullPolicy: 'IfNotPresent',
      highAvailability: {
        replicas: params.controlPlane.replicas,
      },
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
      } + com.makeMergeable(params.controlPlane.resources),
      persistence: {
        volumeClaim: {
          enabled: true,
          retentionPolicy: 'Retain',
          size: params.controlPlane.storageSize,
          storageClass: params.controlPlane.storageClass,
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

local openshift = if params.infrastructure.type == 'openshift' then com.makeMergeable({
  controlPlane: {
    ingress: {
      enabled: false,
    },
  },
}) else {};

{
  'helm-component': component + openshift,
  'helm-overrides': overrides,
}
