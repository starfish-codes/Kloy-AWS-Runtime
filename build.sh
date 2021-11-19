docker run \
    --rm \
    --volume "$(pwd)/:/src" \
    --platform "linux/x86_64" \
    --workdir "/src/" \
    swift:5.5.0-amazonlinux2 \
    swift build --product Examples -c release -Xswiftc -static-stdlib
