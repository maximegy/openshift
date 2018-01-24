sur la machine docker:
docker save -o <nomfichier> <nomimage>
ex : tomcat docker.io/tomcat

copier sur le serveur Openshift et lancer:
docker load -i <nomfichier>

on peut lister les images:
docker images

se connecter en admin à openshift
oc login -u admin -p MDP https://@IP:8443/

récupérer le token utilisateur
oc whoami -t
qHbaN6ydFD-aoOlFL3_KTNqUWOC_qr7LLkzwSHsBokw

récupérer l'adresse du registry
oc get svc -n default | grep registry
docker-registry    172.30.76.252    <none>        5000/TCP                  23h

se connecter au registry
docker login -u admin -p qHbaN6ydFD-aoOlFL3_KTNqUWOC_qr7LLkzwSHsBokw 172.30.76.252:5000

Tag l'image locale:
docker tag docker.io/tomcat 172.30.76.252:5000/<nomprojet>/tomcat

pousser l'image dans le registry
docker push 172.30.76.252:5000/<nomprojet>/tomcat.
