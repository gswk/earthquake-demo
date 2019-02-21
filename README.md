For this demo, we've built an application that tracks earthquake activity and provides a frontend to visualize recent events.

![Architecture of our demo](images/arch.png)

- [**USGS Event Source**](https://github.com/gswk/usgs-event-source) - A custom event source that polls the USGS Earthquake data on a given interval
- [**Geocoder Service**](https://github.com/gswk/geocoder) - Service that takes in earthquake activity, parses it and does a reverse geocode on the coordinates to find the nearest address. Also provides recent activity to the frontend.
- [**Geoquake Frontend**](https://github.com/gswk/earthquake-demo-frontend) - Frontend to visualize and list activity

For information on how to setup and install Knative, make sure to refer to the [official documentation](https://github.com/knative/docs/tree/master/install).

Setup Postgres with Helm
---

Our application will rely on a Postgres database to store events as they come in. Luckily, we can easily set this up locally using [Helm](https://helm.sh/). While this won't configure something we'd use in production, it will serve as a great solution for our demo. We'll assume you have the helm CLI installed, but if not refer to Helm's documentation on how to get it.

First we'll set up a service account in our Kubernetes cluster for Helm to use, and then initalize Helm.

```
kubectl create serviceaccount --namespace kube-system tiller

kubectl create clusterrolebinding tiller \
    --clusterrole cluster-admin \
    --serviceaccount=kube-system:tiller

helm init --service-account tiller
```

Next, we can install Postgres and give it a few arguments. Here, we'll set the password to the "postgres" user account to "devPass" and then create a database called "geocode"

```
helm install --name geocodedb --set postgresqlPassword=devPass,postgresqlDatabase=geocode stable/postgresql
```

Once it's up and running this database will be available internally to our Kubernetes cluster at `geocodedb-postgresql.default.svc.cluster.local`. If you'd like to access it locally, you can forward a local port to your Kubernetes cluster and then connect to it like it was running on your machine.

```
kubectl port-forward --namespace default svc/geocodedb-postgresql 5432:5432

PGPASSWORD="devPass" psql --host 127.0.0.1 -U postgres
```

Prepare to Deploy
---
Before we deploy our frontend and Geocode service, we'll need to install the Kaniko Build Template, which they'll need to build and package our code for us, using [Knative Builds](https://github.com/knative/docs/tree/master/build). Luckily, we can easily install the Build Template by just applying the appropriate YAML:

```
kubectl apply -f https://raw.githubusercontent.com/knative/build-templates/master/kaniko/kaniko.yaml
```

Deploy Geocode Service
---

Our [Geocode service](https://github.com/gswk/geocoder) is responsible for taking in the earthquake events and reverse geocode the coordinates to find the closes street address to make it easier for users to read. Additionally, all events will be written to our Postgres database to be pulled by our event service when requested by the frontend.

**NOTE:** You'll need to update the [geocoder-service.yaml](geocoder-service.yaml) file, changing both instances of `docker.io/gswk/geocoder` to a container registry that your [build service account](https://github.com/knative/docs/blob/master/build/auth.md) has access to.

Once updated, we can apply our [geocoder-service.yaml](geocoder-service.yaml) file to deploy our service:

```
kubectl apply -f geocoder-service.yaml
```