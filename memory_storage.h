
#ifndef TORRENT_MEMORY_STORAGE_HPP_INCLUDED
#define TORRENT_MEMORY_STORAGE_HPP_INCLUDED

#include <chrono>
#include <math.h>

#include <boost/dynamic_bitset.hpp>

#include <libtorrent/error_code.hpp>
#include <libtorrent/bencode.hpp>
#include <libtorrent/storage.hpp>
#include <libtorrent/storage_defs.hpp>
#include <libtorrent/block_cache.hpp>
#include <libtorrent/fwd.hpp>
#include <libtorrent/file.hpp>
#include <libtorrent/entry.hpp>
#include <libtorrent/torrent_info.hpp>
#include <libtorrent/torrent_handle.hpp>
#include <libtorrent/torrent.hpp>
#include <libtorrent/thread.hpp>

using byte = unsigned char;

typedef boost::dynamic_bitset<> Bitset;

using namespace libtorrent;

namespace libtorrent {
        std::int64_t memory_size = 0;

        struct memory_piece 
        {
                mutex* m_mutex;

                int index;
                int length;

                bool completed;
                int size;
                bool read;
                int buffered = -1;

                memory_piece(int i, int length) : index(i), length(length), size(0) {
                        m_mutex = new mutex();
                        buffered = -1;
                };

                bool isBuffered() {
                        return buffered != -1;
                };

                void reset() {
                        mutex::scoped_lock l(*m_mutex);

                        printf("Freeing piece %d, buffer: %d \n", index, buffered);

                        buffered = -1;
                        completed = false;
                        read = false;
                        size = 0;
                }

        };

        struct memory_buffer {
                mutex* m_mutex;

                int index = -1;
                bool used = false;
                int pi = -1;
                int length = 0;
                std::chrono::milliseconds accessed;

                std::vector<char> buffer;

                memory_buffer(int index, int length) : index(index), length(length) {
                        pi = -1;
                        buffer.resize(length);
                        m_mutex = new mutex();
                };

                bool assigned() {
                        return pi != -1;
                };

                bool reserved(Bitset* reservedPieces) {
                        return reservedPieces->test(pi);
                };

                bool readed(Bitset* readerPieces) {
                        return readerPieces->test(pi);
                };

                void reset() {
                        mutex::scoped_lock l(*m_mutex);

                        printf("Freeing buffer %d, piece: %d \n", index, pi);

                        used = false;
                        pi = -1;
                };

        };

        struct memory_storage : storage_interface
        {
                Bitset readerPieces;
                Bitset reservedPieces;

                mutex* m_mutex;

                std::string id;
                std::int64_t capacity;

                int pieceCount = 0;
                std::int64_t pieceLength = 0;
                std::vector<memory_piece> pieces;

                int bufferSize = 0;
                int bufferLimit = 0;
                int bufferUsed = 0;
                std::vector<memory_buffer> buffers;

                file_storage const* m_files;
                torrent_info const& m_info;
                libtorrent::torrent_handle* m_handle;
                bool logging = false;
                bool initialized = false;

                memory_storage(storage_params const& params) : 
                        m_files(params.files), m_info(*params.info) {
                        m_mutex = new mutex();

                        capacity = memory_size;
                };

                ~memory_storage() {};

                void initialize(storage_error& ec) 
                {
                }

                void set_memory_size(std::int64_t s) {
                        capacity = s;

                        printf("Init with mem size %ld, Pieces: %d, Piece length: %d \n", 
                                (long) memory_size, m_info.num_pieces(), m_info.piece_length());

                        pieceCount = m_info.num_pieces();
                        pieceLength = m_info.piece_length();

                        // Using max possible buffers + 2
                        bufferSize = rint(ceil(capacity/pieceLength) + 2);
                        if (bufferSize > pieceCount) {
                                bufferSize = pieceCount;
                        };
                        bufferLimit = bufferSize;

                        printf("Using %d buffers \n", bufferSize);

                        for (int i = 0; i < m_info.num_pieces(); i++) {
                                int size = m_info.piece_size(i);
                                pieces.push_back(memory_piece(i, size));
                        }

                        for (int i = 0; i < bufferSize; i++) {
                                buffers.push_back(memory_buffer(i, pieceLength));
                        }

                        readerPieces.resize(m_info.num_pieces());
                        reservedPieces.resize(m_info.num_pieces());

                        initialized = true;
                }

                bool has_any_file() 
                { 
                        if (logging) {
                                printf("Has \n");
                        };
                        return false; 
                }

                // char* read(int size, int piece, int offset) {
                int read(char* read_buf, int size, int piece, int offset) {
                        if (!initialized) return 0;

                        if (logging) {
                                printf("Read start: %d, off: %d, size: %d \n", piece, offset, size);
                        };

                        if (!getReadBuffer(&pieces[piece])) {
                                printf("     nobuffer: %d, off: %d \n", piece, offset);
                                restore_piece(piece);
                                return -1;
                        };
                        if (pieces[piece].size < pieces[piece].length) {
                                printf("     less: %d, off: %d, size: %d, length: %d \n", piece, offset, pieces[piece].size, pieces[piece].length);
                                restore_piece(piece);
                                return -1;
                        };

                        int available = buffers[pieces[piece].buffered].buffer.size() - offset;
                        if (available <= 0) return 0;
                        if (available > size) available = size;

                        if (logging) {
                                printf("       pre: %d, off: %d, size: %d, available: %d, sizeof: %d \n", piece, offset, size, available, int(sizeof(read_buf)));
                        };
                        memcpy(read_buf, &buffers[pieces[piece].buffered].buffer[offset], available);

                        if (pieces[piece].completed && offset+available >= pieces[piece].size) {
                                pieces[piece].read = true;
                        };

                        buffers[pieces[piece].buffered].accessed = std::chrono::duration_cast< std::chrono::milliseconds >(
                                std::chrono::system_clock::now().time_since_epoch()
                        );

                        return size;
                };

                int readv(libtorrent::file::iovec_t const* bufs, int num_bufs
                        , int piece, int offset, int flags, libtorrent::storage_error& ec)
                {
                        if (!initialized) return 0;

                        if (logging) {
                                printf("Read piece: %d, off: %d \n", piece, offset);
                        };

                        if (!getReadBuffer(&pieces[piece])) {
                                printf("Read fail no buffer: %d, off: %d \n", piece, offset);
                                return 0;
                        };

                        int file_offset = offset;
                        int n = 0;
                        for (int i = 0; i < num_bufs; ++i)
                        {
                                std::memcpy(bufs[i].iov_base, &buffers[pieces[piece].buffered].buffer[file_offset], bufs[i].iov_len);
                                file_offset += bufs[i].iov_len;
                                n += bufs[i].iov_len;
                        };

                        if (pieces[piece].completed && offset+n >= pieces[piece].size) {
                                pieces[piece].read = true;
                        };

                        buffers[pieces[piece].buffered].accessed = std::chrono::duration_cast< std::chrono::milliseconds >(
                                std::chrono::system_clock::now().time_since_epoch()
                        );

                        return n;
                };

                int writev(libtorrent::file::iovec_t const* bufs, int num_bufs
                        , int piece, int offset, int flags, libtorrent::storage_error& ec)
                {
                        if (!initialized) return 0;

                        if (logging) {
                                printf("Write Input: %d, off: %d, bufs: %d \n", piece, offset, bufs_size(bufs, num_bufs));
                        };

                        if (!getWriteBuffer(&pieces[piece])) {
                                if (logging) {
                                        printf("      no buffer: %d \n", piece);
                                };
                                return 0;
                        };

                        int size = bufs_size(bufs, num_bufs);
                        // printf("      piece: %d, size: %d, offset: %d, size: %d, overall: %d \n", 
                                // piece, int(buffers[pieces[piece].buffered].buffer.size()), offset, size, offset+size);
                        if (buffers[pieces[piece].buffered].buffer.size() < offset + size) 
                                buffers[pieces[piece].buffered].buffer.resize(offset + size);

                        int file_offset = offset;
                        int n = 0;
                        for (int i = 0; i < num_bufs; ++i)
                        {
                                std::memcpy(&buffers[pieces[piece].buffered].buffer[file_offset], bufs[i].iov_base, bufs[i].iov_len);
                                file_offset += bufs[i].iov_len;
                                n += bufs[i].iov_len;
                        };

                        pieces[piece].size += n;
                        buffers[pieces[piece].buffered].accessed = std::chrono::duration_cast< std::chrono::milliseconds >(
                                std::chrono::system_clock::now().time_since_epoch()
                        );

                        if (bufferUsed >= bufferLimit) {
                                trim();
                        }

                        return n;
                };

                void rename_file(int index, std::string const& new_filename
                        , libtorrent::storage_error& ec) 
                {
                }

                bool move_storage(std::string const& save_path) 
                { 
                        return false; 
                }

                bool verify_resume_data(libtorrent::bdecode_node const& rd
                        , std::vector<std::string> const* links
                        , libtorrent::storage_error& error) 
                { 
                        return false; 
                }

                bool write_resume_data(libtorrent::entry& rd) const 
                { 
                        return false; 
                }

                void write_resume_data(libtorrent::entry& rd, libtorrent::storage_error& ec) 
                {
                }

                void release_files(libtorrent::storage_error& ec) 
                {
                }

                bool delete_files() 
                { 
                        return false; 
                }

                bool has_any_file(libtorrent::storage_error& ec) 
                { 
                        if (logging) {
                                printf("Has 2 \n");
                        };
                        return false; 
                }

                void set_torrent_handle(libtorrent::torrent_handle* h) {
                        m_handle = h;
                }

                void set_file_priority(std::vector<boost::uint8_t>& prio, libtorrent::storage_error& ec) 
                {
                        if (logging) {
                                printf("Set prio \n");
                        };
                }

                int move_storage(std::string const& save_path, int flags, libtorrent::storage_error& ec) 
                { 
                        if (logging) {
                                printf("Move storage 2 \n");
                        };
                        return 0; 
                }

                void write_resume_data(libtorrent::entry& rd, libtorrent::storage_error& ec) const 
                {
                        if (logging) {
                                printf("Write resume 2 \n");
                        };
                }

                void delete_files(int options, libtorrent::storage_error& ec) {
                        if (logging) {
                                printf("Delete file 2 \n");
                        };
                };

                bool getReadBuffer(memory_piece* p) {
                        return getBuffer(p, false);
                };

                bool getWriteBuffer(memory_piece* p) {
                        return getBuffer(p, true);
                };

                bool getBuffer(memory_piece *p, bool isWrite) {
                        if (p->isBuffered()) {
                                return true;
                        };

                        if (!p->isBuffered() && isWrite) {
                                mutex::scoped_lock l(*m_mutex);

                                for (int i = 0; i < bufferSize; i++) {
                                        if (buffers[i].used) {
                                                continue;
                                        };

                                        if (logging) {
                                                printf("Setting buffer %d to piece %d \n", buffers[i].index, p->index);
                                        };

                                        buffers[i].used = true;
                                        buffers[i].pi = p->index;
                                        buffers[i].accessed = std::chrono::duration_cast< std::chrono::milliseconds >(
                                                std::chrono::system_clock::now().time_since_epoch()
                                        );

                                        p->buffered = buffers[i].index;

                                        // If we are placing permanent buffer entry - we should reduce the limit,
                                        // to propely check for the usage.
                                        if (reservedPieces.test(p->index)) {
                                                bufferLimit--;
                                        } else {
                                                bufferUsed++;
                                        };

                                        break;
                                }
                        }

                        return p->isBuffered();
                };

                void trim() {
                        if (capacity < 0 || bufferUsed < bufferLimit) {
                                return;
                        };

                        mutex::scoped_lock l(*m_mutex);

                        while (bufferUsed >= bufferLimit) {
                                if (logging) {
                                        printf("Trimming %d to %d \n", bufferUsed, bufferLimit);
                                };
                                if (!readerPieces.empty()) {
                                        int minIndex = 0;
                                        std::chrono::milliseconds minTime;

                                        for (auto it = buffers.begin(); it != buffers.end(); ++it) 
                                        {
                                                if (it->used && it->assigned() && !it->reserved(&reservedPieces) && !it->readed(&readerPieces) && (minIndex == 0 || it->accessed < minTime)) {
                                                        minIndex = it->pi;
                                                        minTime = it->accessed;
                                                };
                                        };

                                        if (minIndex > 0) {
                                                removePiece(minIndex);
                                                continue;
                                        };
                                }

                                int minIndex = 0;
                                std::chrono::milliseconds minTime;

                                for (auto it = buffers.begin(); it != buffers.end(); ++it)
                                {
                                        if (it->used && it->assigned() && !it->reserved(&reservedPieces) && (minIndex == 0 || it->accessed < minTime)) {
                                                minIndex = it->pi;
                                                minTime = it->accessed;
                                        }
                                };

                                if (minIndex > 0) {
                                        removePiece(minIndex);
                                        continue;
                                };
                        }

                };

                void removePiece(int pi) {
                        // Don't allow to delete reserved pieces
                        if (!pieces[pi].isBuffered() || buffers[pieces[pi].buffered].reserved(&reservedPieces)) {
                                return;
                        }

                        if (logging) {
                                printf("Removing piece %d, buffer: %d \n", pi, pieces[pi].buffered);
                        };

                        buffers[pieces[pi].buffered].reset();
                        pieces[pi].reset();

                        bufferUsed--;

                        restore_piece(pi);
                }
                
                void restore_piece(int pi) {
                        if (logging) {
                                printf("Restoring piece: %d \n", pi);
                        };
                        libtorrent::torrent* t = m_handle->native_handle().get();
                        if (!t) return;

                        printf("Restoring piece2: %d \n", pi);

                        t->picker().reset_piece(pi);
                        printf("Restoring piece3: %d \n", pi);
                }

                void enable_logging() {
                        logging = true;
                }

                void disable_logging() {
                        logging = false;
                }

                void update_reader_pieces(std::vector<int> pieces) {
                        if (!initialized) return;

                        readerPieces.reset();
                        for (auto i = pieces.begin(); i != pieces.end(); ++i) {
                                readerPieces.set(*i);
                        };
                };

                void update_reserved_pieces(std::vector<int> pieces) {
                        if (!initialized) return;

                        reservedPieces.reset();
                        for (auto i = pieces.begin(); i != pieces.end(); ++i) {
                                reservedPieces.set(*i);
                        };
                };

        };

        storage_interface* memory_storage_constructor(storage_params const& params)
        {
                return new memory_storage(params);
        };
}

#endif // TORRENT_MEMORY_STORAGE_HPP_INCLUDED
