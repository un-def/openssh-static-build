root := invocation_dir()
work_dir := root / 'workdir'
build_dir := work_dir / 'build'
prefix := work_dir / 'prefix'
build_script := root / 'build.sh'
run_script := root / 'run.sh'

@_list:
  just --list --unsorted

@build: clean
  docker run --rm \
    -v '{{work_dir}}:/workdir' \
    -v '{{build_script}}:/build.sh' \
    -w /workdir \
    alpine:latest \
    /build.sh $(id -u) $(id -g)

clean: clean-build clean-prefix clean-tarball

clean-build:
  rm -rf '{{build_dir}}'

clean-prefix:
  rm -rf '{{prefix}}'

clean-tarball:
  rm -f *.tar.gz

@run port='2222':
  '{{run_script}}' {{port}} '{{prefix}}'

@pack-sshd:
  tar -czf sshd-static.tar.gz -C '{{prefix}}' \
    sbin/sshd \
    libexec/sshd-session \
    etc/sshd_config \
    etc/ssh_host_ed25519_key \
    "$(realpath -s --relative-to '{{prefix}}' '{{run_script}}')"
