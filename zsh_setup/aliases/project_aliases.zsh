alias uproj="cp ~/REPOS/convenience/zsh_setup/aliases/project_aliases.zsh ~/.oh-my-zsh/custom/project_aliases.zsh;source ~/.zshrc"
# Completion function for "project"
_project() {
  local curcontext="$curcontext" state line
  typeset -A opt_args

  _arguments -C \
    '1:command:(create switch archive remove export enter exit)' \
    '2:project name:->projects' && return 0

  if [[ $words[2] == (enter|switch|archive|remove|export) ]]; then
    local containers

    containers=(${(f)"$(
      docker ps -a --format '{{.CreatedAt}} {{.Names}}' |
      sort -r |
      awk '{ $1=$2=$3=$4=""; sub(/^ +/, ""); print }'
    )"})

    _describe 'containers (newest first)' containers
  fi
}

compdef _project project
