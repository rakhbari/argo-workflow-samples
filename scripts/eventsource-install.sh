export GITHUB_ORG=${1}
export EVENTS_FQDN=${2}

if ! command -v envsubst &> /dev/null
then
  echo "ERROR: envsubst isn't installed/can't be found. Get it installed on your machine before proceeding. https://www.google.com/search?q=envsubst+command+not+found"
  exit 2
fi

usage() {
  echo ""
  echo "Usage: ${0} <GITHUB_ORG> <EVENTS_FQDN>"
  echo ""
  exit 1
}

if [ -z "${GITHUB_ORG}" ] || [ -z "${EVENTS_FQDN}" ]; then
  echo "ERROR: GITHUB_ORG and EVENTS_FQDN are required."
  usage
fi

echo ""
echo "===> Installing EventSource for Github org \"${GITHUB_ORG}\" and Events FQDN \"${EVENTS_FQDN}\" ..."
SCRIPT_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
envsubst < ${SCRIPT_DIR}/../argo-events/eventsource-github.yaml | kubectl apply -n argo-events -f -
echo ""
