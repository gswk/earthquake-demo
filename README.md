[Geocoder Service](https://github.com/gswk/geocoder)

[USGS Event Source](https://github.com/gswk/usgs-event-source)


Use Helm to create postgres database
--
```
kubectl create serviceaccount --namespace kube-system tiller

kubectl create clusterrolebinding tiller \
    --clusterrole cluster-admin \
    --serviceaccount=kube-system:tiller

helm init --service-account tiller

helm install --name geocodedb --set postgresqlPassword=devPass,postgresqlDatabase=geocode stable/postgresql

```

Hostname of postgres database
`geocodedb-postgresql.default.svc.cluster.local`

Connect to postgres databse locally
```
kubectl port-forward --namespace default svc/geocodedb-postgresql 5432:5432 &
    PGPASSWORD="devPass" psql --host 127.0.0.1 -U postgres
```