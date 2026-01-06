apiVersion: v1
kind: Secret
metadata:
  name: talos-values
  namespace: kube-system
stringData:
  machineCA: ${caMachine}
  machineToken: ${tokenMachine}
  clusterID: ${clusterID}
  clusterSecret: ${clusterSecret}
  clusterEndpoint: https://${apiDomain}:6443
  clusterName: ${clusterName}
