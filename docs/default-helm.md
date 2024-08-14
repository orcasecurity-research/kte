# Default helm chart
The default helm located at [deployment/clusters/helm/kte](https://github.com/orcasecurity/kte/tree/master/deployment/clusters/helm/kte) has the following misconfigurations:

| #  |                    Name                     |                                 Description                                 |                              Tactic                              |                          |
|----|:-------------------------------------------:|:---------------------------------------------------------------------------:|:----------------------------------------------------------------:|:------------------------:|
| 1  |         ***cluster-admin** binding*         |  A k8s sa is assigned to a cluster-wide / namespaced `cluster-admin` Role   | [Privilege Escalation](https://attack.mitre.org/tactics/TA0004/) | <ul><li>- [x] </li></ul> |
| 2  |            ***hostPath** mount*             |                 A hostPath volume is mounted into a k8s pod                 |   [Lateral Movement](https://attack.mitre.org/tactics/TA0008/)   | <ul><li>- [x] </li></ul> |
| 3  |         ***privileged** container*          |   The `privileged: true` security context in assigned to a container spec   | [Privilege Escalation](https://attack.mitre.org/tactics/TA0004/) | <ul><li>- [x] </li></ul> |
| 4  |     ***neglected** config-map / secret*     |        A k8s configMap / secret that isn't assigned to any workload         |      [Collection](https://attack.mitre.org/tactics/TA0009/)      | <ul><li>- [x] </li></ul> |
| 5  |     ***default** namespace deployment*      |            A k8s workload deployed inside the default namespace             | [Privilege Escalation](https://attack.mitre.org/tactics/TA0004/) | <ul><li>- [x] </li></ul> |
| 6  | ***cmd.exe or bash** allowed on container*  |       A k8s workload container allows the `CAP_SYS_PTRACE` capability       |   [Lateral Movement](https://attack.mitre.org/tactics/TA0008/)   | <ul><li>- [x] </li></ul> |
| 7  |      *no **network policies** defined*      |           The k8s cluster doesn't define any network access rules           |   [Lateral Movement](https://attack.mitre.org/tactics/TA0008/)   | <ul><li>- [x] </li></ul> |
| 8  |  ***default sa** is bound to a deployment*  |                The default sa is assigned to a k8s workload                 | [Privilege Escalation](https://attack.mitre.org/tactics/TA0004/) | <ul><li>- [x] </li></ul> |
| 9  | ***impersonation allowed** on a deployment* |       A k8s workload with a sa that allows the impersonate permission       |   [Lateral Movement](https://attack.mitre.org/tactics/TA0008/)   | <ul><li>- [x] </li></ul> |
