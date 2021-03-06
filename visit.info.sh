## cd history mechanism.

export CDHISTFILE=~/.cdhistory
if [ -e "$CDHISTFILE" ]
then
    cdht=`mktemp`
    tail -500 "$CDHISTFILE" > $cdht
    mv "$cdht" "$CDHISTFILE"
fi

function keep_cd_history() {
    if [ -z "$1" ] ; then d="$HOME" ; else d="$1" ; fi
    cdhcan=`readlink -f "$d"`
    if 'cd' "$d"
    then
        echo -e `date +%s`"\t"$cdhcan >> $CDHISTFILE
    fi
}
function pick_cwd_from_history() {
    f=~/.cdhistgo
    cdhistpick "$f"
    if [ -r "$f" ] ; then cd "`head -1 $f`" ; fi
}

alias cd=keep_cd_history
alias cdh=pick_cwd_from_history
