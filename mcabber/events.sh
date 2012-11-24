#!/bin/sh


#   $events_command MSG IN jabber@id [file] (when receiving a message)
#   $events_command MSG OUT jabber@id       (when sending a message)
#   $events_command MSG MUC room_id [file]  (when receiving a MUC message)
#   $events_command STATUS X jabber@id      (new buddy status is X)
#   $events_command UNREAD "N x y z"        (number of unread buddy buffers)
#
#   $4 is provided for incoming messages only when 'event_log_files' is enabled

send_notification() {
    echo 'naughty.notify({title = "'$1'", text = "'$2'"})' | awesome-client
}

ACTION_TYPE=$1

if [ $ACTION_TYPE = "MSG" ]; then
    MSG_DIRECTION=$2
    case "$MSG_DIRECTION" in
        IN|MUC)
            if [ -n "$4" -a -f "$4" ]; then
                MSG="$(cat $4 | perl -pe 's/\*//g')"
                send_notification "New message from $3" "$( echo $MSG | fold -s -w 50)"
                rm $4
            else
                send_notification "New message from $3" ""
            fi ;;
        OUT) ;;
    esac
elif [ $ACTION_TYPE = "STATUS" ]; then
    case "$2" in
         #_|I)    send_notification "$3" "$3 has signed off.";;
         O|F)    send_notification "$3" "$3 is now online." ;;
         #A|N)    send_notification "$3" "$3 has gone away." ;;
         #D)      send_notification "$3" "$3 does not want to be disturbed.";;
         X)      send_notification "$3" "$3 sent a request." ;;
    esac
elif [ $1 = "UNREAD" ]; then
    NBR_MESSAGES=`echo $2 | tr ' ' '+' | bc`
    send_notification "Unread messages" "There are $NBR_MESSAGES new messages."
fi

