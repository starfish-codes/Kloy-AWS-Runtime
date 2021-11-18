default: build 

build:
	@echo "🔨 Building with docker"
	docker run \
		--rm \
	  	--volume "$(pwd)/:/src" \
	  	--platform "linux/x86_64" \
	  	--workdir "/src/" \
	  	swift:5.5-amazonlinux2 \
	  	/bin/bash -c "yum -y install libuuid-devel libicu-devel libedit-devel libxml2-devel sqlite-devel python-devel ncurses-devel curl-devel openssl-devel libtool jq tar zip && swift build --product Examples -c release && scripts/package.sh Examples"

