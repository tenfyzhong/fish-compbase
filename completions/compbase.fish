function __compbase_complete_items
    set -l cmd (commandline -poc)
    if test "$cmd[-1]" = '-t' || test "$cmd[-1]" = '--topic'
        compbase topic -l
        return 0
    end

    if test "$cmd[-1]" = '-l' || test "$cmd[-1]" = '--list' || test "$cmd[-1]" = '-a' || test "$cmd[-1]" = '--add' || test "$cmd[-1]" = '-D' || test "$cmd[-1]" = '--description'
        return 0
    end

    set -e cmd[1] # compbase
    set -e cmd[1] # item
    argparse -i 't/topic=' -- $cmd 2>/dev/null
    compbase item -t "$_flag_topic" -l
end

complete compbase -r -f
complete compbase -s h -l help -d 'print thie help message'
complete compbase -f -n '! __fish_seen_subcommand_from topic item conf -h --help' -a 'topic' -d 'manages topics'
complete compbase -f -n '! __fish_seen_subcommand_from topic item conf -h --help' -a 'item' -d 'manages items'
complete compbase -f -n '! __fish_seen_subcommand_from topic item conf -h --help' -a 'conf' -d 'get or set config of a topic'

complete compbase -f -n '__fish_seen_subcommand_from topic' -s h -l help -d 'print this help message'
complete compbase -f -n '__fish_seen_subcommand_from topic' -s l -l list -d 'list topics'
complete compbase -f -n '__fish_seen_subcommand_from topic' -s a -l add -d 'add topics'
complete compbase -f -n '__fish_seen_subcommand_from topic' -s d -l delete -d 'delete topics'
complete compbase -f -n '__fish_seen_subcommand_from topic' -s d -l delete -d 'delete topics'
complete compbase -f -n '__fish_seen_subcommand_from topic' -s m -l move -d 'move <old> to <new>'
complete compbase -r -f -n '__fish_seen_subcommand_from topic' -a "(compbase topic -l)"

complete compbase -f -n '__fish_seen_subcommand_from item' -s h -l help -d 'print this help message'
complete compbase -r -f -n '__fish_seen_subcommand_from item' -s t -l topic -a "(__compbase_complete_items)" -d 'the items belong to the topic'
complete compbase -f -n '__fish_seen_subcommand_from item' -s l -l list -d 'list items'
complete compbase -f -n '__fish_seen_subcommand_from item' -s a -l add -d 'add items'
complete compbase -r -f -n '__fish_seen_subcommand_from item' -s D -l description -d 'add description to the complete item'
complete compbase -f -n '__fish_seen_subcommand_from item' -s d -l delete -d 'delete items'
complete compbase -r -f -n '__fish_seen_subcommand_from item' -a "(__compbase_complete_items)"

complete compbase -f -n '__fish_seen_subcommand_from conf' -s h -l help -d 'print this help message'
complete compbase -r -f -n '__fish_seen_subcommand_from conf' -s t -l topic -a "(compbase topic -l)" -d 'the config of the topic to process'
complete compbase -r -f -n '__fish_seen_subcommand_from conf' -s g -l get -a "max_item" -d 'get value of the key'
complete compbase -r -f -n '__fish_seen_subcommand_from conf' -s s -l set -a "max_item" -d 'set value to the key'
