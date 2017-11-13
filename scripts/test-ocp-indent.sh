#!/bin/sh

tmp_dir="$(mktemp -d -t tezos_build.XXXXXXXXXX)"
failed=no

for f in  ` find \( -name _build -or \
                    -name .git -or \
                    -wholename ./src/environment/v1.ml -or \
                    -name registerer.ml \) -prune -or \
                 \( -name \*.ml -or -name \*.mli \) -print`; do
  ff=$(basename $f)
  ocp-indent $f > $tmp_dir/$ff
  diff -u --color $f $tmp_dir/$ff
  if [ $? -ne 0 ]; then
      failed=yes
  fi
  rm -f $tmp_dir/$ff $tmp_dir/$ff.diff
done

if [ $failed = "yes" ]; then
    exit 2
fi