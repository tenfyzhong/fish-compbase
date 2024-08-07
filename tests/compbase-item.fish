function init
    set -gx COMPBASE_DATA (command mktemp -d)
    # echo "COMPBASE_DATA:$COMPBASE_DATA"
end

function deinit
    rm -rf $COMPBASE_DATA
    set -eg COMPBASE_DATA
end

init
compbase topic -a foo
set items (compbase item -t foo -l | string collect)
@test 'no item' "$items" = ''

compbase item -t foo -a hello.world
set items (compbase item -t foo -l | string collect)
@test 'item hello.world' "$items" = "hello.world	"

compbase item -t foo1 -a hello.world -D 'foobar'
set items (compbase item -t foo1 -l | string collect)
@test 'item hello.world' "$items" = "hello.world	foobar"

compbase item -t foo -d hello.world
set items (compbase item -t foo -l | string collect)
@test 'no item' "$items" = ''

@test 'argpase failed no topic' (compbase item -t) $status = 21
@test 'argpase failed no description' (compbase item -t topic -D) $status = 21

@test 'argpase failed topic empty' (compbase item -t '') $status = 22


@test 'add empty' (compbase item -t bar -a) $status = 23
@test 'delete empty' (compbase item -t bar -d) $status = 24

compbase item -t foobar -a hello
@test 'add repeat' (compbase item -t foobar -a hello) $status = 0
set items (compbase item -t foobar -l | string collect)
@test 'item hello' "$items" = "hello	"

compbase item -t foo2item -a hello -D helloDescription
compbase item -t foo2item -a world -D worldDescription
set item (compbase item -t foo2item -l | string collect)
@test 'add 2 items' "$item" = 'world	worldDescription
hello	helloDescription'

compbase topic -a foomax1
__compbase_conf_max_item foomax1 1
compbase item -t foomax1 -a hello
compbase item -t foomax1 -a world
set item (compbase item -t foomax1 -l | string collect)
@test 'max 1' "$item" = "world	"
compbase item -t foomax1 -a foobar
set item (compbase item -t foomax1 -l | string collect)
@test 'max 1' "$item" = "foobar	"

compbase item -t footab -D 'foo	bar' -a 'foo	hello'
set item (compbase item -t footab -l | string collect)
@test 'has tab' "$item" = "foo hello	foo bar"
deinit
