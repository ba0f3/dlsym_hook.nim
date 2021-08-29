if [ "${ORCHESTRA_ROOT}x" = "x" ]; then
  echo "Error: ORCHESTRA_ROOT is not set"
  exit 1
fi

$ORCHESTRA_ROOT/bin/revng-lift -g ll dummy dummy.translated.ll