%{
#include "alert.hpp"
#include "alert_manager.hpp"
%}

// std::auto_ptr cuases problems, so we ignore the methods which use it
%ignore libtorrent::alert::clone;
%ignore libtorrent::log_alert;
%ignore libtorrent::peer_log_alert;
%ignore libtorrent::portmap_log_alert;
%ignore libtorrent::torrent_log_alert;
%ignore libtorrent::stats_alert;
%ignore libtorrent::picker_log_alert;

%include "alert.hpp"
%include "alert_manager.hpp"

%{
    using libtorrent::time_point;
%}
