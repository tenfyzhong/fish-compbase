function init
    set -gx COMPBASE_DATA (command mktemp -d)
    # echo "COMPBASE_DATA:$COMPBASE_DATA"
end

function deinit
    rm -rf $COMPBASE_DATA
    set -eg COMPBASE_DATA
end

init
@test 'parse failed' (compbase conf -g) "$status" = 31
@test 'no topic' (compbase conf -g max_item) "$status" = 32
@test 'topic empty' (compbase conf -t '' -g max_item) "$status" = 32
@test 'get unknown key' (compbase conf -t conffoo -g max_item1) "$status" = 0
set conf (compbase conf -t conffoo -g max_item)
@test 'get key max_item'  "$conf" = 100
@test 'set unknown key' (compbase conf -t conffoo -s max_item1 50) "$status" = 34
@test 'set no value' (compbase conf -t conffoo -s max_item) "$status" = 33
@test 'set succ' (compbase conf -t conffoo -s max_item 50) "$status" = 0
set conf (compbase conf -t conffoo -g max_item)
@test 'get key max_item'  "$conf" = 50
deinit
