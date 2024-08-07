function init
    set -gx COMPBASE_DATA (command mktemp -d)
end

function deinit
    rm -rf $COMPBASE_DATA
    set -eg COMPBASE_DATA
end

init
set topics (compbase topic -l | string collect)
@test 'test no topic' "$topics" = ''
deinit

init
compbase topic -a foo
set topics (ls $COMPBASE_DATA | string collect)
@test 'test add topic foo'  "$topics" = 'foo.sqlite3'
compbase topic -d foo
set topics (ls $COMPBASE_DATA | string collect)
@test 'test remove topic foo' "$topics" = ''
compbase topic -a foo bar
set topics (ls $COMPBASE_DATA | string collect)
@test 'test add topic foo bar' "$topics" = "bar.sqlite3
foo.sqlite3"
deinit

init
compbase topic -a foo
compbase topic -m foo bar
set topics (ls $COMPBASE_DATA | string collect)
@test 'test move topic foo bar' "$topics" = "bar.sqlite3"
deinit

init
compbase topic -d foo
set topics (ls $COMPBASE_DATA | string collect)
@test 'test remove not exist' "$topics" = ""
deinit

init
@test 'test move source not exist' (compbase topic -m foo bar) $status = 12
compbase topic -a foo bar
@test 'test move target exist' (compbase topic -m foo bar) $status = 13
deinit

init
compbase topic -a ''
set topics (compbase topic -l | string collect)
@test 'test add empty topic' "$topics" = ''
deinit
