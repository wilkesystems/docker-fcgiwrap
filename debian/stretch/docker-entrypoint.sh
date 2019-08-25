#!/bin/bash
set -eo pipefail
shopt -s nullglob

main() {
    case "$1" in
        fcgiwrap )
            args=$(getopt -n "$(basename $0)" -o d:a:p:s:M:F:b:u:g:U:G:m:hv --long help,version -- "$@")
            eval set --"$args"
            while true; do
                case "$1" in
                    -d )
                        FCGI_DIR="$2"
                        shift 2
                        ;;
                    -a )
                        FCGI_ADDR="$2"
                        shift 2
                        ;;
                    -p )
                        FCGI_PORT="$2"
                        shift 2
                        ;;
                    -s )
                        FCGI_SOCKET="$2"
                        shift 2
                        ;;
                    -M )
                        FCGI_SOCKET_MODE="$2"
                        shift 2
                        ;;
                    -F )
                        FCGI_CHILDREN="$2"
                        shift 2
                        ;;
                    -b )
                        FCGI_BACKLOG="$2"
                        shift 2
                        ;;
                    -u )
                        FCGI_USER="$2"
                        shift 2
                        ;;
                    -g )
                        FCGI_GROUP="$2"
                        shift 2
                        ;;
                    -U )
                        FCGI_SOCKET_OWNER="$2"
                        shift 2
                        ;;
                    -G )
                        FCGI_SOCKET_GROUP="$2"
                        shift 2
                        ;;
                    -m )
                        CPANM[${#CPANM[@]}]="$2"
                        shift 2
                        ;;
                    -h | --help )
                        print_usage fcgiwrap
                        exit
                        ;;
                    -v | --version )
                        print_version
                        exit
                        ;;
                    --) shift ; break ;;
                    * ) break ;;
                esac
            done
            for CPANM_MODULE in ${CPANM[@]}; do
                $0 cpanm $CPANM_MODULE
            done
            start_server
	    ;;
	cpanm )
            args=$(getopt -n "$(basename $0)" -o hv --long help,version -- "$@")
            eval set --"$args"
            while true; do
                case "$1" in
                    -h | --help )
                        print_usage cpanm
                        exit
			;;
                    -v | --version )
                        print_version
                        exit
			;;
                    --) shift ; break ;;
                    * ) break ;;
                esac
            done
            shift $((OPTIND))
	    for arg; do
                if [ -f /usr/bin/cpanm ]; then
                    /usr/bin/cpanm $arg 2>&1 >/dev/null
                fi
	    done
	    exit
	    ;;
        -v | --version )
            print_version
            exit 1
            ;;
        * )
            print_usage
            exit 2
            ;;
    esac
    return
}

start_server() {
    PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

    SPAWN_FCGI="/usr/bin/spawn-fcgi"
    DAEMON="/usr/sbin/fcgiwrap"
    NAME="fcgiwrap"
    DESC="FastCGI wrapper"

    test -x $SPAWN_FCGI || exit 0
    test -x $DAEMON || exit 0

    DAEMON_OPTS="-f"

    ENV_VARS="PATH='$PATH'"

    if [ -n "$FCGI_UID" ]; then
        usermod -u $FCGI_UID $FCGI_USER
    fi

    if [ -n "$FCGI_GID" ]; then
        groupmod -g $FCGI_GID $FCGI_GROUP
    fi

    ARGS="-n"

    if [ -z $FCGI_CHILDREN ]; then
        ARGS="$ARGS -F 1"
    fi

    ARGS="$ARGS -F $FCGI_CHILDREN"

    if [ -z $FCGI_USER ]; then
        ARGS="$ARGS -u www-data"
    fi

    ARGS="$ARGS -u $FCGI_USER"

    if [ -z $FCGI_GROUP ]; then
        FCGI_GROUP="www-data"
    fi

    ARGS="$ARGS -u $FCGI_GROUP"

    if [ -n "$FCGI_BACKLOG" ]; then
        ARGS="$ARGS -b $FCGI_BACKLOG"
    fi

    if [ -n "$FCGI_DIR" ]; then
        ARGS="$ARGS -d $FCGI_DIR"
    fi

    if [ -z $FCGI_SOCKET ]; then
        FCGI_SOCKET="/var/run/fcgiwrap/$NAME.socket"
    fi

    if [ -z $FCGI_SOCKET_OWNER ]; then
        FCGI_SOCKET_OWNER="www-data"
    fi

    if [ -z $FCGI_SOCKET_GROUP ]; then
        FCGI_SOCKET_GROUP="www-data"
    fi

    if [ -z $FCGI_ADDR ]; then
        FCGI_ADDR="0.0.0.0"
    fi

    if [ -z $FCGI_PORT ]; then
        FCGI_PORT="9000"
    fi

    sed -i -e "s/dc_eximconfig_configtype=.*/dc_eximconfig_configtype='internet'/" /etc/exim4/update-exim4.conf.conf
    sed -i -e "s/dc_other_hostnames=.*/dc_other_hostnames='$(hostname)'/" /etc/exim4/update-exim4.conf.conf
    sed -i -e "s/dc_local_interfaces=.*/dc_local_interfaces='127.0.0.1'/" /etc/exim4/update-exim4.conf.conf

    echo $(hostname) > /etc/mailname

    update-exim4.conf

    sed -i 's/^\(\[supervisord\]\)$/\1\nnodaemon=true/' /etc/supervisor/supervisord.conf

    echo -e "[program:fcgiwrapsock]" > /etc/supervisor/conf.d/fcgiwrap.conf
    echo -e "command=$SPAWN_FCGI $ARGS -s $FCGI_SOCKET -U $FCGI_SOCKET_OWNER -G $FCGI_SOCKET_GROUP -- $DAEMON $DAEMON_OPTS" >> /etc/supervisor/conf.d/fcgiwrap.conf
    echo -e "stdout_logfile=/var/log/supervisor/fcgiwrap-stdout.log" >> /etc/supervisor/conf.d/fcgiwrap.conf
    echo -e "stderr_logfile=/var/log/supervisor/fcgiwrap-stderr.log" >> /etc/supervisor/conf.d/fcgiwrap.conf
    echo -e "autorestart=true\n" >> /etc/supervisor/conf.d/fcgiwrap.conf

    echo -e "[program:fcgiwrap]" >> /etc/supervisor/conf.d/fcgiwrap.conf
    echo -e "command=$SPAWN_FCGI $ARGS -a $FCGI_ADDR -p $FCGI_PORT -- $DAEMON $DAEMON_OPTS" >> /etc/supervisor/conf.d/fcgiwrap.conf
    echo -e "stdout_logfile=/var/log/supervisor/fcgiwrap-stdout.log" >> /etc/supervisor/conf.d/fcgiwrap.conf
    echo -e "stderr_logfile=/var/log/supervisor/fcgiwrap-stderr.log" >> /etc/supervisor/conf.d/fcgiwrap.conf
    echo -e "autorestart=true" >> /etc/supervisor/conf.d/fcgiwrap.conf

    echo -e "[program:cron]" > /etc/supervisor/conf.d/cron.conf
    echo -e "command=/usr/sbin/cron -f" >> /etc/supervisor/conf.d/cron.conf
    echo -e "stdout_logfile=/var/log/supervisor/cron-stdout.log" >> /etc/supervisor/conf.d/cron.conf
    echo -e "stderr_logfile=/var/log/supervisor/cron-stderr.log" >> /etc/supervisor/conf.d/cron.conf
    echo -e "autorestart=true" >> /etc/supervisor/conf.d/cron.conf

    echo -e "[program:exim4]" > /etc/supervisor/conf.d/exim4.conf
    echo -e "command=/usr/sbin/exim4 -bd -v" >> /etc/supervisor/conf.d/exim4.conf
    echo -e "stdout_logfile=/var/log/supervisor/exim4-stdout.log" >> /etc/supervisor/conf.d/exim4.conf
    echo -e "stderr_logfile=/var/log/supervisor/exim4-stderr.log" >> /etc/supervisor/conf.d/exim4.conf
    echo -e "autorestart=true" >> /etc/supervisor/conf.d/exim4.conf

    ln -sf /dev/stdout /var/log/supervisor/fcgiwrap-stdout.log
    ln -sf /dev/stderr /var/log/supervisor/fcgiwrap-stderr.log
    ln -sf /dev/stdout /var/log/supervisor/cron-stdout.log
    ln -sf /dev/stderr /var/log/supervisor/cron-stderr.log
    ln -sf /dev/stdout /var/log/supervisor/exim4-stdout.log
    ln -sf /dev/stderr /var/log/supervisor/exim4-stderr.log

    exec supervisord -c /etc/supervisor/supervisord.conf
}

print_usage() {
    case "$1" in
        fcgiwrap )
cat <<EOF
Usage: $(basename $0) fcgiwrap [options]

Options:
 -d <directory>    chdir to directory before spawning
 -a <address>      bind to IPv4/IPv6 address (defaults to 0.0.0.0)
 -p <port>         bind to TCP-port
 -s <path>         bind to Unix domain socket
 -M <mode>         change Unix domain socket mode (octal integer, default: allow
                   read+write for user and group as far as umask allows it)
 -F <children>     number of children to fork (default 1)
 -b <backlog>      backlog to allow on the socket (default 1024)
 -c <directory>    chroot to directory
 -u <user>         change to user-id
 -g <group>        change to group-id (default: primary group of user if -u
                   is given)
 -U <user>         change Unix domain socket owner to user-id
 -G <group>        change Unix domain socket group to group-id
 -m <module>       install modules with cpanm

 -h, --help        display this help and exit
 -v, --version     output version information and exit

EOF
            ;;
        cpanm )
cat <<EOF
Usage: $(basename $0) cpanm [options] Module [...]

Options:
 -h, --help        display this help and exit
 -v, --version     output version information and exit

EOF
            ;;
        * )
cat <<EOF
Usage:  $(basename $0) Command [...]

Options:
 -h, --help        display this help and exit
 -v, --version     output version information and exit

Commands:
  fcgiwrap         Execute Simple server for running CGI applications over FastCGI
  cpanm            Install Perl Modules with CPANM

Run '$(basename $0) COMMAND --help' for more information on a command.
EOF
            ;;
    esac
    return
}

print_version() {
cat <<EOF

Docker Entrypoint v1.0.0 - FastCGI wrapper

MIT License

Copyright (c) 2017 Wilke.Systems

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

EOF
    return
}

main $@

exit
