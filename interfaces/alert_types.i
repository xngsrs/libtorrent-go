%{
#include <libtorrent/operations.hpp>
#include <libtorrent/close_reason.hpp>
#include "alert_types.hpp"
%}

%extend libtorrent::save_resume_data_alert {
    entry resume_data() const {
        boost::shared_ptr<libtorrent::entry> ptr;
        ptr = boost::make_shared<libtorrent::entry>(*self->resume_data);
        return *ptr;
    }
}
%ignore libtorrent::save_resume_data_alert::resume_data;

%include <libtorrent/operations.hpp>
%include <libtorrent/close_reason.hpp>
//alert_type keeps making problems
%include "alert_types.hpp"
//%include "alert_types_mod.hpp"
