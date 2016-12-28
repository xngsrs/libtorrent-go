
%ignore libtorrent::file_status;
%ignore libtorrent::handle_type;
%ignore libtorrent::block_cache;
%ignore libtorrent::cached_piece_entry;

// Fewer errors but still...
namespace libtorrent {
	struct iovec_t
	{
    char *iov_base;
    u_long iov_len;
  };
}
