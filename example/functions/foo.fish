function foo
    argparse 'o/opt=' -- $argv 2>/dev/null

    echo "$_flag_opt"
    compbase item -t foo_opt -D "foo_opt" -a "$flag_opt"
end
