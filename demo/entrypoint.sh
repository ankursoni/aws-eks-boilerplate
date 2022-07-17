#!/bin/bash
###########################################################################
#Script Name  : entrypoint.sh
#Description  : Acts as an entrypoint for the demo container image to act
#               as an api or a migration job
#Args         : $1 - runtime behavior indicator -
#               'api', 'migrate' or 'migrateThenApi'
#             : $* - remaining args are passed through to the 'api' command
###########################################################################

# source ${VENV_PATH}/bin/activate

function api() {
    FLASK_ENV=development python -m demo.app "$@"
}
function migrate() {
    alembic -c ./demo/alembic_dev.ini upgrade head
}

mode=$1
shift
case ${mode} in
api)
    api "$@"
    ;;
migrate)
    migrate
    ;;
migrateThenApi)
    migrate && api "$@"
    ;;
*)
    echo "Usage api | migrate | migrateThenApi"
    exit 1
    ;;
esac
