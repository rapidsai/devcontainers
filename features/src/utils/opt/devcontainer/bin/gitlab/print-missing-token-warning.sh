echo "A GitLab token is required to authenticate via GitLab CLI, but a 'GITLAB_TOKEN' envvar was not detected." 1>&2;
echo "" 1>&2;
echo "Generate a token with 'api' and 'write_repository' scopes at https://${GITLAB_HOST:-gitlab.com}/-/profile/personal_access_tokens" 1>&2;

if "${CODESPACES:-false}"; then
echo "To skip this prompt in the future, add the token as a GitHub codespaces secret named 'GITLAB_TOKEN' at https://github.com/settings/codespaces." 1>&2;
echo "   ** Be sure to allow the repo that launched this codespace access to the new 'GITLAB_TOKEN' secret **" 1>&2;
fi
