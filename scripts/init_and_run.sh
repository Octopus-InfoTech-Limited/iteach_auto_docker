#!/usr/bin/env sh
set -euo

SERVICE=${1:-}
case "$SERVICE" in
  api)
    REPO=${ITEACH_API_REPO:-}
    REF=${ITEACH_API_REF:-}
    DIR=/workspace/iteach_api
    ;;
  web)
    REPO=${ITEACH_WEB_REPO:-}
    REF=${ITEACH_WEB_REF:-}
    DIR=/workspace/iteach_web
    ;;
  *)
    echo "Unknown service '$SERVICE'. Use 'api' or 'web'." >&2
    exit 1
    ;;
esac

add_jdbc_props() {
  PROP_FILE="$DIR/src/main/resources/application.properties"
  if [ ! -f "$PROP_FILE" ]; then
    echo "application.properties not found at $PROP_FILE; skipping JDBC injection." >&2
    return
  fi

  if [ -z "${JDBC_DRIVERCLASSNAME:-}" ] || [ -z "${JDBC_URL:-}" ] || [ -z "${JDBC_USERNAME:-}" ] || [ -z "${JDBC_PASSWORD:-}" ]; then
    echo "JDBC_* env vars not fully set; skipping JDBC injection." >&2
    return
  fi

  TMP_FILE="$(mktemp)"
  awk 'BEGIN{skip=0} /# by iteach_auto_docker - start/{skip=1; next} /# by iteach_auto_docker - end/{skip=0; next} !skip{print}' "$PROP_FILE" > "$TMP_FILE"

  {
    printf '\n'
    printf '# by iteach_auto_docker - start\n'
    printf 'jdbc.driverClassName = %s\n' "$JDBC_DRIVERCLASSNAME"
    printf 'jdbc.url = %s\n' "$JDBC_URL"
    printf 'jdbc.username = %s\n' "$JDBC_USERNAME"
    printf 'jdbc.password = %s\n' "$JDBC_PASSWORD"
    printf '# by iteach_auto_docker - end\n'
  } >> "$TMP_FILE"

  mv "$TMP_FILE" "$PROP_FILE"
}

mkdir -p "$DIR"
mkdir -p /workspace/iteach_uploads/upload/iteach/userFiles

CLONED=0
if [ ! -d "$DIR/.git" ]; then
  if [ -z "$REPO" ]; then
    echo "Repository URL not set for $SERVICE. Set the appropriate env var and retry." >&2
    exit 1
  fi
  git clone "$REPO" "$DIR"
  CLONED=1
fi

cd "$DIR"

# Only apply REF on first clone unless FORCE_RESET_ON_START=true
if [ -n "${REF:-}" ]; then
  if [ "$CLONED" = "1" ] || [ "${FORCE_RESET_ON_START:-false}" = "true" ]; then
    git checkout "$REF"
    git fetch --all --prune
    git reset --hard "$REF"
  fi
fi

if [ "$SERVICE" = "api" ]; then
  add_jdbc_props
fi

: "${JAVA_OPTS:=--add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.time=ALL-UNNAMED}"
: "${MAVEN_OPTS:=--add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.time=ALL-UNNAMED}"
export JAVA_OPTS MAVEN_OPTS

exec mvn -DskipTests spring-boot:run
