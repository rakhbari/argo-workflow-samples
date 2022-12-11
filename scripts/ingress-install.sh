export ARGO_FQDN=${1}
export TLS_CERT_SECRET_NAME=${2}

if ! command -v envsubst &> /dev/null
then
  echo "ERROR: envsubst isn't installed/can't be found. Get it installed on your machine before proceeding. https://www.google.com/search?q=envsubst+command+not+found"
  exit 2
fi

usage() {
  echo ""
  echo "Usage: ${0} <ARGO_FQDN> <TLS_CERT_SECRET_NAME>"
  echo ""
  exit 1
}

if [ -z "${ARGO_FQDN}" ] || [ -z "${TLS_CERT_SECRET_NAME}" ]
then
  echo "ERROR: ARGO_FQDN and TLS_CERT_SECRET_NAME are required."
  usage
fi

echo ""
echo "===> Installing IngressRoute for FQDN \"${ARGO_FQDN}\" using TLS cert secret \"${TLS_CERT_SECRET_NAME}\" ..."
SCRIPT_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
envsubst < ${SCRIPT_DIR}/../install/ingress-argo-server-ui.yaml | kubectl apply -f -
echo ""
