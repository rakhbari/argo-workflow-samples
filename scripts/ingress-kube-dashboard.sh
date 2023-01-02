export K8S_DASHBOARD_FQDN=${1}
export TLS_CERT_SECRET_NAME=${2}

if ! command -v envsubst &> /dev/null
then
  echo "ERROR: envsubst isn't installed/can't be found. Get it installed on your machine before proceeding. https://www.google.com/search?q=envsubst+command+not+found"
  exit 2
fi

usage() {
  echo ""
  echo "Usage: ${0} <K8S_DASHBOARD_FQDN> <TLS_CERT_SECRET_NAME>"
  echo ""
  exit 1
}

if [ -z "${K8S_DASHBOARD_FQDN}" ] || [ -z "${TLS_CERT_SECRET_NAME}" ]
then
  echo "ERROR: K8S_DASHBOARD_FQDN, and TLS_CERT_SECRET_NAME are required."
  usage
fi

echo ""
echo "===> Installing IngressRoute for FQDN \"${K8S_DASHBOARD_FQDN}\" ..."
SCRIPT_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
envsubst < ${SCRIPT_DIR}/../install/ingress-kubernetes-dashboard.yaml | kubectl apply -n kubernetes-dashboard -f -
echo ""
