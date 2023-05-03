export ICC_VERSION="${ICC_VERSION}";
if [ -n "${PATH##*"/opt/intel/oneapi/compiler/${ICC_VERSION}/linux/bin"*}" ]; then
    export PATH="$PATH:/opt/intel/oneapi/compiler/${ICC_VERSION}/linux/bin";
fi
