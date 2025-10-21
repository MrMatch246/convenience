# Completion function for "project"
_project() {
  local curcontext="$curcontext" state line
  typeset -A opt_args

  _arguments -C \
    '1:command:(create switch archive remove export enter exit addfeat enterfeat)' \
    '2:project name or feature:->dynamic' && return 0

  case ${words[2]} in
    enter|switch|archive|remove|export)
      local containers
      containers=(${(f)"$(
        docker ps -a --format '{{.CreatedAt}} {{.Names}}' |
        sort -r |
        awk '{ $1=$2=$3=$4=""; sub(/^ +/, ""); print }'
      )"})
      _describe 'containers (newest first)' containers
      ;;

    enterfeat)
      local current_file="$HOME/Documents/Engagements/Running/.current_project"
      if [[ -f "$current_file" ]]; then
        local current_project=$(<"$current_file")
        local features_file="$HOME/Documents/Engagements/Running/$current_project/.features"
        if [[ -f "$features_file" ]]; then
          local features=(${(f)"$(cat $features_file)"})
          _describe 'features in current project' features
        else
          compadd "No .features file found for $current_project"
        fi
      else
        compadd "No current project set"
      fi
      ;;

    addfeat)
      local available_features=(mobsf)
      _describe 'available features to add' available_features
      ;;
  esac
}

compdef _project project
