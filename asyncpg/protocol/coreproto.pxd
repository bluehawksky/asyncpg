cdef enum ConnectionStatus:
    CONNECTION_OK = 1
    CONNECTION_BAD = 2
    CONNECTION_STARTED = 3           # Waiting for connection to be made.


cdef enum ProtocolState:
    PROTOCOL_IDLE = 0

    PROTOCOL_FAILED = 1

    PROTOCOL_ERROR_CONSUME = 2

    PROTOCOL_AUTH = 10
    PROTOCOL_PREPARE = 11
    PROTOCOL_BIND_EXECUTE = 12
    PROTOCOL_CLOSE_STMT_PORTAL = 13
    PROTOCOL_SIMPLE_QUERY = 14
    PROTOCOL_EXECUTE = 15


cdef enum ResultType:
    RESULT_OK = 1
    RESULT_FAILED = 2


cdef enum TransactionStatus:
    PQTRANS_IDLE = 0                 # connection idle
    PQTRANS_ACTIVE = 1               # command in progress
    PQTRANS_INTRANS = 2              # idle, within transaction block
    PQTRANS_INERROR = 3              # idle, within failed transaction
    PQTRANS_UNKNOWN = 4              # cannot determine status


ctypedef object (*decode_row_method)(object, const char*, int32_t)


cdef class CoreProtocol:
    cdef:
        ReadBuffer buffer
        bint _skip_discard

        ConnectionStatus con_status
        ProtocolState state
        TransactionStatus xact_status

        str encoding

        object transport

        # Dict with all connection arguments
        dict con_args

        int32_t backend_pid
        int32_t backend_secret

        ## Result
        ResultType result_type
        object result
        bytes result_param_desc
        bytes result_row_desc
        bytes result_status_msg

        # True - completed, False - suspended
        bint result_execute_completed

    cdef _process__auth(self, char mtype)
    cdef _process__prepare(self, char mtype)
    cdef _process__bind_execute(self, char mtype)
    cdef _process__close_stmt_portal(self, char mtype)
    cdef _process__simple_query(self, char mtype)

    cdef _parse_msg_authentication(self)
    cdef _parse_msg_parameter_status(self)
    cdef _parse_msg_backend_key_data(self)
    cdef _parse_msg_ready_for_query(self)
    cdef _parse_data_msgs(self)
    cdef _parse_msg_error_response(self, is_error)
    cdef _parse_msg_command_complete(self)

    cdef _write(self, buf)
    cdef inline _write_sync_message(self)

    cdef _read_server_messages(self)

    cdef _push_result(self)
    cdef _reset_result(self)
    cdef _set_state(self, ProtocolState new_state)

    cdef _ensure_connected(self)

    cdef _connect(self)
    cdef _prepare(self, str stmt_name, str query)
    cdef _bind_execute(self, str portal_name, str stmt_name,
                       WriteBuffer bind_data, int32_t limit)
    cdef _execute(self, str portal_name, int32_t limit)
    cdef _close(self, str name, bint is_portal)
    cdef _simple_query(self, str query)

    cdef _decode_row(self, const char* buf, int32_t buf_len)

    cdef _on_result(self)
    cdef _set_server_parameter(self, name, val)
    cdef _on_connection_lost(self, exc)
