function compbase --description 'A database to manage completion items'
    argparse -s 'h/help' -- $argv 2>/dev/null
    if test $status -ne 0
        return 1
    end

    if set -q _flag_help
        __compbase_help
        return 0
    end

    if test -z "$argv"
        __compbase_help
        return 1
    end

    set -l subcommand $argv[1]
    set -l rest $argv[2..-1]

    if test -z "$COMPBASE_DATA"
        set -gx COMPBASE_DATA "$HOME/.local/state/compbase/data"
    end
    mkdir -p "$COMPBASE_DATA"


    switch "$subcommand"
        case topic
            __compbase_topic $rest
        case item
            __compbase_item $rest
        case conf
            __compbase_conf $rest
        case '*'
            __compbase_help
            return 2
    end


end

function __compbase_topic
    argparse 'l/list' 'a/add' 'd/delete' 'm/move' 'h/help' -- $argv 2>/dev/null
    if test $status -ne 0
        return 10
    end

    if set -q _flag_help
        __compbase_topic_help
        return
    end

    if set -q _flag_list
        __compbase_topic_list
        return
    end

    if set -q _flag_add
        __compbase_topic_add $argv
        return
    end

    if set -q _flag_delete
        __compbase_topic_delete $argv
        return
    end

    if set -q _flag_move
        __compbase_topic_move $argv
        return
    end
end

function __compbase_topic_list
    set files (ls $COMPBASE_DATA)
    for file in $files
        if string match -q -- '*.sqlite3' "$file"
            set topic (string sub -e -8 "$file")
            set topic (__compbase_unescape "$topic")
            echo $topic
        end
    end
end

function __compbase_topic_add
    if test -z "$argv"
        return 11
    end

    for topic in $argv
        if test -z "$topic"
            continue
        end

        set file (__compbase_file_of_topic "$topic")
        if test -f "$file"
            continue
        end

        # create table compitem
        sqlite3 "$file" "CREATE TABLE IF NOT EXISTS compitem(id INTEGER PRIMARY KEY, item TEXT, desc TEXT, update_time INTEGER)"
        sqlite3 "$file" "CREATE UNIQUE INDEX IF NOT EXISTS uniq_item on compitem(item)"
        sqlite3 "$file" "CREATE INDEX IF NOT EXISTS key_update_time on compitem(update_time DESC)"

        # create table compconf
        sqlite3 "$file" "CREATE TABLE IF NOT EXISTS compconf(id INTEGER PRIMARY KEY, key TEXT, value TEXT)"
        sqlite3 "$file" "CREATE UNIQUE INDEX IF NOT EXISTS uniq_key on compconf(key)"

        # conf max_num
        __compbase_conf_max_item "$topic" 100
    end
end

function __compbase_topic_delete
    if test -z "$argv"
        return 11
    end

    for topic in $argv
        set file (__compbase_file_of_topic "$topic")
        if test ! -f "$file"
            continue
        end
        rm -f $file
    end
end

function __compbase_topic_move
    if test (count $argv) -ne 2
        return 11
    end
    set old "$argv[1]"
    set new "$argv[2]"

    set old_file (__compbase_file_of_topic "$old")
    set new_file (__compbase_file_of_topic "$new")
    if test ! -f "$old_file"
        return 12
    end
    if test -f "$new_file"
        return 13
    end
    mv -f "$old_file" "$new_file"
end

function __compbase_item
    argparse 't/topic=' 'l/list' 'a/add' 'D/description=' 'd/delete' 'h/help' -- $argv 2>/dev/null
    if test $status -ne 0
        return 21
    end

    if set -q _flag_help
        __compbase_item_help
        return 0
    end

    set topic "$_flag_topic"
    if test -z "$topic"
        return 22
    end

    set description (string replace -a "\t" " " "$_flag_description")

    __compbase_topic -a "$topic"

    if set -q _flag_list
        __compbase_item_list "$topic"
        return
    end

    if set -q _flag_add
        __compbase_item_add "$topic" "$description" $argv
        return
    end

    if set -q _flag_delete
        __compbase_item_delete "$topic" $argv
        return
    end
end

function __compbase_item_list -a topic
    set file (__compbase_file_of_topic "$topic")
    # separator is \t which will sperate the completion item and description
    sqlite3 -separator "	" "$file"  'SELECT item,desc FROM compitem ORDER BY update_time DESC, id DESC'
end

function __compbase_item_add -a topic -a description
    if test (count $argv) -lt 3
        return 23
    end
    set items $argv[3..-1]

    # format description
    set description (string replace '	' ' ' $description)

    set file (__compbase_file_of_topic "$topic")

    set now (date +%s)
    set now (string trim $now)
    for item in $items
        if test -z "$item"
            continue
        end
        # format item
        set item (string replace '	' ' ' $item)
        sqlite3 "$file" "INSERT OR REPLACE INTO compitem(id, item, desc, update_time) VALUES((SELECT id FROM compitem WHERE item='$item'), '$item', '$description', $now)"
    end
end

function __compbase_item_delete -a topic
    if test (count $argv) -lt 2
        return 24
    end
    set items $argv[2..-1]
    set file (__compbase_file_of_topic "$topic")
    for item in $items
        sqlite3 "$file" "DELETE FROM compitem WHERE item='$item'"
    end
end

function __compbase_conf
    argparse 't/topic=' 's/set=' 'g/get=' 'h/help' -- $argv 2>/dev/null
    if test $status -ne 0
        return 31
    end

    if set -q _flag_help
        __compbase_conf_help
        return 0
    end

    set topic "$_flag_topic"
    if test -z "$topic"
        return 32
    end

    __compbase_topic -a "$topic"

    if set -q _flag_get
        __compbase_conf_get "$topic" "$_flag_get"
        return
    end

    if set -q _flag_set
        if test (count $argv) -eq 0
            return 33
        end
        __compbase_conf_set "$topic" "$_flag_set" "$argv[1]"
        return
    end
end

function __compbase_conf_get -a topic -a key
    set file (__compbase_file_of_topic "$topic")
    sqlite3 "$file" "SELECT value FROM compconf where key='$key'"
end

function __compbase_conf_set -a topic -a key -a value
    switch "$key"
        case max_item
            __compbase_conf_max_item "$topic" "$value"
        case '*'
            return 34
    end
end

function __compbase_escape -a name
    string escape --style=url $name
end

function __compbase_unescape -a name
    string unescape --style=url $name
end

function __compbase_file_of_topic -a topic
    set name (__compbase_escape "$topic")
    set file "$COMPBASE_DATA/$name.sqlite3"
    echo -n $file
end

function __compbase_conf_max_item -a topic -a num
    if test -z "$num"
        return 35
    end
    if ! string match -qr '^[0-9]+$' -- "$num"
        return 36
    end
    if test "$num" -le 0
        set num 100
    end

    set file (__compbase_file_of_topic "$topic")

    # set a trigger delete the old items if the count of items greate than $num
    sqlite3 "$file" "INSERT OR REPLACE INTO compconf(id, key, value) VALUES((SELECT id FROM compconf WHERE key='max_item'), 'max_item', '$num')"
    sqlite3 "$file" "DROP TRIGGER IF EXISTS trigger_max_item"
    sqlite3 "$file" "CREATE TRIGGER trigger_max_item AFTER INSERT ON compitem WHEN (SELECT COUNT(*) from compitem) > $num
BEGIN
    DELETE FROM compitem WHERE compitem.id NOT IN (SELECT compitem.id FROM compitem ORDER BY compitem.update_time DESC, compitem.id DESC LIMIT $num);
END;"

    sqlite3 "$file" "DELETE FROM compitem WHERE id NOT IN (SELECT id FROM compitem ORDER BY update_time DESC, id DESC LIMIT $num)"
end

function __compbase_help
    printf %s\n\
        'compbase: A database to manage completion items'\
        'Usage: compbase <opts> [subcommand] <opts...> <args...>'\
        ''\
        'Options:'\
        '  -h/--help               print this help message'\
        ''\
        'Subcommands:'\
        '  topic                   manage topic'\
        '  item                    manage completion item'\
        '  conf                    get or set config of a topic'
end

function __compbase_topic_help
    printf %s\n\
        'compbase topic: Topics are sets for the completion items. The topic command manages topics'\
        'Usage: compbase topic <opts...> <args...>'\
        ''\
        'Options:'\
        '  -l/--list               list topics'\
        '  -a/--add                add topics'\
        '  -d/--delete             delete topics'\
        '  -m/--move <old> <new>   move <old> to <new>'\
        '  -h/--help               print this help message'
end

function __compbase_item_help
    printf %s\n\
        'compbase item: Items are completion items for a special topic. The item command manages items'\
        'Usage: compbase item <opts...> <args...>'\
        ''\
        'Options:'\
        '  -t/--topic <topic>       the items belong to the topic'\
        '  -l/--list                list items'\
        '  -a/--add                 add items'\
        '  -D/--description <desc>  add description to the completion item'\
        '  -d/--delete <item ...>   delete items'\
        '  -h/--help                print this help message'
end

function __compbase_conf_help
    printf %s\n\
        'compbase conf: Get or set config of a topic'\
        'Usage: compbase conf <opts> [value]'\
        ''\
        'Options:'\
        '  -t/--topic <topic>   the config of the topic to process'\
        '  -g/--get <key>       get the value of the key, key:[max_item]'\
        '  -s/--set <key>       set value to the key, the key same as the --get option'\
        '  -h/--help            print this help message'\
        ''\
        'Conf:'\
        '  max_item: item count for a topic, default:100'
end
