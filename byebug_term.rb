# TODO: send one-liner PR to byebug that would simplify this a lot.

# Enter byebug from a background by launching a terminal with byebug client.
# Only works on same machine, under X.  (tmux left as excercise to reader)
#
# USAGE:
#   1. Have this file loaded (eg. put it in config/initializers/)
#   2. Write `byebug_term` in place of `byebug`.
#   3. If you don't have/like gnome-terminal, set BYEBUG_TERM_COMMAND env var
#      to `xterm -e` or similar.
# 
# You'll get one window per process (that hits the byebug_term).
# You can `s`tep, `c`ontinue etc. as usual.
# Note that stdout is NOT to this term, so `puts`, `pp` etc don't work.
# TODO: if you close a terminal, won't work again from that process.

# https://github.com/deivid-rodriguez/byebug/blob/master/lib/byebug/remote.rb

# The easy way to open a server and block until a client connects is
# setting `Byebug.wait_connection = true`.  Alas, then `start_server`
# doesn't give us a chance to launch a terminal with a client after
# it's listening.  And we can't launch before `start_server` unless
# we already know what port it'll listen on.
#
# Nasty "solution": check whether any `RemoteInterface` exists to know
# if a term is connected.

def byebug_has_client?
  require 'byebug/core'

  ObjectSpace.each_object(Byebug::RemoteInterface).count > 0
end

def byebug_ensure_server
  require 'byebug/core'

  return if Byebug.actual_port
  Byebug.start_server('localhost', 0)  # pick an available port
  until Byebug.actual_port
    puts "~~~~~~ Bybug.actual_port = #{Byebug.actual_port} Bybug.actual_control_port = #{Byebug.actual_control_port}"
    sleep(0.2)
  end
  $log.info "Byebug.start_server: listening on port #{Byebug.actual_port}"
rescue => e
  $log.error "Couldn't Byebug.start_server: #{e}"
  $log.exception(e)
  return
end

def byebug_term
  require 'byebug/core'

  byebug_ensure_server

  unless byebug_has_client?
    term = ENV.fetch("BYEBUG_TERM_COMMAND", "gnome-terminal -x")
    system("#{term} byebug -R localhost:#{Byebug.actual_port} &")

    until byebug_has_client?
      sleep(0.2)
    end
  end

  #byebug        # would open debugger here
  Byebug.attach  # opens debugger in caller (it's what `byebug` calls)
end
