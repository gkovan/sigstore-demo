# sigstore-demo

This contains the content used to demo sigstore at the OpenShift Commons Briefing on March 30, 2021; a recording of this can be found at [https://www.youtube.com/watch?v=yKrbUGSwrEw](https://www.youtube.com/watch?v=yKrbUGSwrEw).

Slides from the presentation can be seen at: [https://speakerdeck.com/redhatopenshift/secure-your-open-source-supply-chain-with-sigstore](https://speakerdeck.com/redhatopenshift/secure-your-open-source-supply-chain-with-sigstore).

## Setup

### Setup Infrastructure

From OpenShift Operator Hub, install OpenShift Pipelines Operator.

Note:
The Tekton resources in this repo main branch work with OpenShift Pipelines 1.2.3.
This is the version for OCP 4.6.

If you have OCP 4.7, you have to specifically select the OCP 4.6 channel to install Pipelines 1.2.3.

Create a project/namespace called `sigstore-demo-gk`
```
oc new-project sigstore-demo-gk
```

Add pipeline service account to the priveleged scc:
```
oc adm policy add-scc-to-user privileged -z pipeline
```

Create the registry-credentials secret:
```
kubectl create secret docker-registry registry-credentials --docker-server=https://index.docker.io/v2/  --docker-username=gkovan --docker-email=gkovan@hotmail.com --docker-password=my-fake-password -n sigstore-demo-gk
```

Patch the pipeline service account with the image pull secret:
```
kubectl patch serviceaccount pipeline \
  -p "{\"imagePullSecrets\": [{\"name\": \"registry-credentials\"}]}" -n sigstore-deme-gk
```

### Create the base image used in the scenario in your personal image registry (i.e. dockerhub)

Pull the base image:
```
docker pull registry.access.redhat.com/ubi8/ubi-minimal:8.3
```

Create a tag to of the image to reference the dockerhub repo:
```
docker tag registry.access.redhat.com/ubi8/ubi-minimal:8.3  gkovan/ubi8-minimal:8.3
```

Push the base image to image registry
```
docker push gkovan/ubi8-minimal:8.3
```

Sign the image
```
export COSIGN_EXPERIMENTAL=1
```

```
cosign sign -a mode=keyless gkovan/ubi8-minimal:8.3
```

Verify the image is signed
```
cosign verify gkovan/ubi8-minimal:8.3
```


### Create Tekton Tasks

```shell
oc apply -f ./config/tekton/task
```

### Create Tekton Pipeline

```shell
oc apply -f ./config/tekton/pipeline
```

### Create Tekton Trigger

```shell
oc apply -f ./config/tekton/trigger
```

### Expose Tekton Event Listener Service

Once the `el-sigstore-demo-app` service has been created by Tekton, expose it
by running:

```shell
oc expose service el-sigstore-demo-app
```

### Add GitHub Webhook Manually

Open GitHub repo (Go to Settings > Webhooks) click on `Add webhook`. Under
Payload URL, paste the output of:

```shell
echo $(oc get route el-sigstore-demo-app --template='http://{{.spec.host}}')
```

Select Content type as `application/json`. Add secret eg: `sigstore`. Click on
`Add Webhook`.

### Test It

Now when we perform any push event on the repo, it will trigger the pipeline
with a new pipeline run. To test it, run:

```shell
git commit -m "empty-commit" --allow-empty && git push origin main
```
