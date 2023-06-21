#!/usr/bin/env zsh
#!nix-shell -i zsh -p zsh postgresql

set -eu -o pipefail

export BASE="${1:-$(mktemp -d)}"
shift
echo "Postgres base is $BASE"

export PGDATA="$BASE"/db
if [[ -z "${PGPORT:-}" ]]; then
  PGPORT=5432
fi
export PGPORT
export PGHOSTADDR=0.0.0.0
#export POSTGREST_CONF_DIR="$BASE"/data
export LOG="$BASE"/pg.log

#mkdir -p "$POSTGREST_CONF_DIR"

export INFO_NAME="$(whoami)"
if ! [[ -d "$BASE"/db ]]; then
  initdb
  createdb --help -O "$INFO_NAME" "$INFO_NAME"
fi

pg_ctl -w -l "$LOG" start
pg_hook() {
    echo running exit hook . . .
    pg_ctl -l "$LOG" stop
}
trap pg_hook EXIT

for SCHEMA in "$@"; do
  echo $SCHEMA
  if [[ ! -z "$SCHEMA" ]]; then
      psql < "$SCHEMA"
  fi
done


#(( POSTGRESTPORT = (RANDOM % 1024) + 5432 ))
#while nc -vz $POSTGRESTPORT; do
# (( POSTGRESTPORT = (RANDOM % 1024) + 5432 ))
#done

echo
echo ---------------------------------------------
echo

#cat <<EOF
#db-uri = "postgres://$INFO_NAME@localhost:$PGPORT/$INFO_NAME"
#db-schema = "public"
#db-anon-role = "elangley"
#server-port = "$POSTGRESTPORT"
#EOF

echo
echo ---------------------------------------------
echo

set +e +u +o pipefail

no-o-op() { }
trap no-o-op INT

printf '\n\nPostgres database at postgres://%s@localhost:%d/%s\n' "$INFO_NAME" "$PGPORT" "$INFO_NAME"
printf 'Serving REST API on http://localhost:%d\n\n\n' "$POSTGRESTPORT"

#postgrest "$POSTGREST_CONF_DIR"/postgrest.conf

read "?done"
