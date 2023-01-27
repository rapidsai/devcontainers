2>& echo "A GitLab token is required to authenticate via GitLab CLI in GitHub codespaces, but a 'GITLAB_TOKEN' secret was not detected.";
2>& echo "";
2>& echo "1. Generate a token with 'api' and 'write_repository' scopes at https://gitlab.com/-/profile/personal_access_tokens";
2>& echo "2. Add the token as a GitHub codespaces secret named 'GITLAB_TOKEN' at https://github.com/settings/codespaces.";
2>& echo "   ** Be sure to allow the repo that launched this codespace access to the new 'GITLAB_TOKEN' secret **";
2>& echo "3. Relaunch this codespace";
