export EVENTSOURCE_NAME=${1}
export EVENTS_FQDN=${2}
export TLS_CERT_SECRET_NAME=${3}

if ! command -v envsubst &> /dev/null
then
  echo "ERROR: envsubst isn't installed/can't be found. Get it installed on your machine before proceeding. https://www.google.com/search?q=envsubst+command+not+found"
  exit 2
fi

usage() {
  echo ""
  echo "Usage: ${0} <EVENTSOURCE_NAME> <EVENTS_FQDN> <TLS_CERT_SECRET_NAME>"
  echo ""
  exit 1
}

if [ -z "${EVENTSOURCE_NAME}" ] || [ -z "${EVENTS_FQDN}" ] || [ -z "${TLS_CERT_SECRET_NAME}" ]
then
  echo "ERROR: EVENTSOURCE_NAME, EVENTS_FQDN, and TLS_CERT_SECRET_NAME are required."
  usage
fi

echo ""
echo "===> Installing IngressRoute for EventSource \"${EVENTSOURCE_NAME}\" and FQDN \"${EVENTS_FQDN}\" ..."
SCRIPT_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
envsubst < ${SCRIPT_DIR}/../argo-events/ingress-github-eventsource.yaml | kubectl apply -f -
echo ""
