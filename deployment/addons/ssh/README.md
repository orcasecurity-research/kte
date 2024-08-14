# k8s pod tunneling 
Most tools' dashboards are exported via a k8s service with type: `CluserIP`. This was intended, to enhance security and prevent exposure of sensitive information. To reach the dashboards, we will be deploying an openssh-server application as a Kubernetes pod, and tunnel through it. The container image we are using is the popular [linuxserver/openssh-server](https://hub.docker.com/r/linuxserver/openssh-server), with a slight change that will allow dynamic port forwarding (i.e. ssh tunneling). You can view the change [here](https://github.com/linuxserver/docker-openssh-server/compare/master...roin-orca:docker-openssh-server:master).

## usage
```sh
./tunnel.sh <vendor>
```

Example:

```sh
./tunnel.sh eks
```

Running the script will:
1. Create ssh keys on your behalf using `ssh-keygen`
2. Inject the pub key to the .tf files
3. Deploy an openssh-server Kubernetes pod using `ghcr.io/roin-orca/openssh-server`
4. Connect to the server with a local sock5 proxy on port 9999
   
You can then configure your browser with a [proxy](https://chromewebstore.google.com/detail/proxy-switchyomega/padekgcemlokbadohgkifijomclgjgif?hl=en)
Chrome Extension to easily connect to the tools' dashboards.

> ℹ️ This project is alpine based, and thus not affected by [CVE-2024-6387](https://www.qualys.com/regresshion-cve-2024-6387/)
[![Screenshot 2024-07-02 at 16 50 34](https://github.com/orcasecurity/kte/assets/120920375/0d4083c2-1fc7-4f0d-bdc6-44f63792f920)](https://discord.com/channels/354974912613449730/1006323310742736987/threads/1257310907592343643)


<details>
<summary>Demo</summary>

https://github.com/orcasecurity/kte/assets/120920375/a3659dae-dced-41ec-909d-5e094bf8e62a

</details>

