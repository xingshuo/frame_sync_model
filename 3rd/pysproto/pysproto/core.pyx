cdef extern from "sproto.h":
    enum: SPROTO_REQUEST
    enum: SPROTO_RESPONSE
    enum: SPROTO_TINTEGER
    enum: SPROTO_TBOOLEAN
    enum: SPROTO_TSTRING
    enum: SPROTO_TSTRUCT
    enum: SPROTO_CB_ERROR
    enum: SPROTO_CB_NIL
    enum: SPROTO_CB_NOARRAY

    struct sproto:
        pass
    struct sproto_type:
        pass
    struct sproto_arg:
        void *ud
        const char *tagname
        int tagid
        int type
        sproto_type *subtype
        void *value
        int length
        int index
        int mainindex
        int extra

    sproto* sproto_create(void *, size_t)
    void sproto_release(sproto*)
    sproto_type* spt "sproto_type"(sproto*, char*)
    int sproto_pack(void*, int, void*, int)
    int sproto_unpack(void*, int, void*, int)
    int sproto_prototag(const sproto *, const char * name)
    const char * sproto_protoname(const sproto *, int proto)
    sproto_type * sproto_protoquery(const sproto *, int proto, int what)
    int sproto_protoresponse(const sproto*, int)
    void sproto_dump(sproto*)
    ctypedef int (*sproto_callback)(const sproto_arg *args) except *
    int sproto_encode(const sproto_type *, void * buffer, int size, sproto_callback cb, void *ud)
    int sproto_decode(const sproto_type *, const void * data, int size, sproto_callback cb, void *ud)

from cpython.pycapsule cimport *
from libc.stdint cimport *
from libc.stdio cimport printf
from libc.string cimport memcpy
from cpython.mem cimport PyMem_Malloc, PyMem_Free, PyMem_Realloc
from cpython.object cimport PyObject
from cpython.exc cimport PyErr_Occurred, PyErr_Print

cdef extern from "compat.h":
    ctypedef void (*capsule_dest)(PyObject *)
    object make_capsule(void *, const char *, capsule_dest)
    void* get_pointer(object, const char*)


cdef enum:
    prealloc = 2050
    max_deeplevel = 64

cdef void *invalid_ptr = <void*>(-1)

cdef struct encode_ud:
    PyObject *data
    int deep

cdef int _encode(const sproto_arg *args) except *:
    cdef encode_ud *self = <encode_ud*>args.ud
    # todo check deep
    data = <object>self.data
    obj = None
    tn = args.tagname
    if args.index > 0:
        try:
            c = data[tn]
        except KeyError:
            return SPROTO_CB_NOARRAY
        if args.mainindex >= 0:
            # c is a dict
            assert isinstance(c, dict)
            c = c.values()
            c.sort()
        try:
            obj = c[args.index-1]
        except IndexError:
            return SPROTO_CB_NIL
    else:
        obj = data.get(tn)
        if obj == None:
            return SPROTO_CB_NIL
    cdef int64_t v, vh
    cdef double vn
    cdef char* ptr
    cdef encode_ud *sub
    if args.type == SPROTO_TINTEGER:
        if args.extra:
            vn = obj
            v = int(vn*args.extra+0.5)
        else:
            v = obj
        vh = v >> 31
        if vh == 0 or vh == -1:
            (<int32_t *>args.value)[0] = <int32_t>v;
            return 4
        else:
            (<int64_t *>args.value)[0] = <int64_t>v;
            return 8
    elif args.type == SPROTO_TBOOLEAN:
        v = obj
        (<int *>args.value)[0] = <int>v
        return 4
    elif args.type == SPROTO_TSTRING:
        ptr = obj
        v = len(obj)
        if v > args.length:
            return SPROTO_CB_ERROR
        memcpy(args.value, ptr, <size_t>v)
        return v
    elif args.type == SPROTO_TSTRUCT:
        sub = <encode_ud *>PyMem_Malloc(sizeof(encode_ud))
        try:
            sub.data = <PyObject *>obj
            sub.deep = self.deep + 1
            r = sproto_encode(args.subtype, args.value, args.length, _encode, sub)
            if r < 0:
                return SPROTO_CB_ERROR
            return r
        finally:
            PyMem_Free(sub)
    raise Exception("Invalid field type %d"%args.type)

def encode(stobj, data):
    assert isinstance(data, dict)
    cdef encode_ud self
    cdef sproto_type *st = <sproto_type*>get_pointer(stobj, NULL)
    if st == invalid_ptr:
        return ""
    cdef char* buf = <char*>PyMem_Malloc(prealloc)
    cdef int sz = prealloc
    try:
        while 1:
            self.data = <PyObject*>data
            self.deep = 0
            r = sproto_encode(st, buf, sz, _encode, &self)
            if PyErr_Occurred():
                PyErr_Print()
                raise Exception("encode error")
            if r < 0:
                sz = sz*2
                buf = <char*>PyMem_Realloc(buf, sz)
            else:
                ret = buf[:r]
                return ret
    finally:
        PyMem_Free(buf)

cdef struct decode_ud:
    PyObject* data
    PyObject* key
    int deep
    int mainindex_tag

cdef int _decode(const sproto_arg *args) except *:
    cdef decode_ud *self = <decode_ud *>args.ud
    self_d = <dict>self.data
    # todo check deep
    if args.index != 0:
        if args.tagname not in self_d:
            if args.mainindex >= 0:
                c = {}
            else:
                c = []
            self_d[args.tagname] = c
        else:
            c = self_d[args.tagname]
        if args.index < 0:
            return 0

    ret = None 
    cdef decode_ud *sub
    if args.type == SPROTO_TINTEGER:
        if args.extra:
            ret = (<int64_t *>args.value)[0]
            ret = <double>ret/args.extra
        else:
            ret = (<int64_t *>args.value)[0]
    elif args.type == SPROTO_TBOOLEAN:
        ret = True if (<int64_t *>args.value)[0] > 0 else False
    elif args.type == SPROTO_TSTRING:
        ret = (<char *>args.value)[:args.length]
    elif args.type == SPROTO_TSTRUCT:
        sub = <decode_ud *>PyMem_Malloc(sizeof(decode_ud))
        try:
            sub.deep = self.deep + 1
            sub_d = {}
            sub.data = <PyObject *>sub_d
            if args.mainindex >= 0:
                sub.mainindex_tag = args.mainindex
                r = sproto_decode(args.subtype, args.value, args.length, _decode, sub)
                if r < 0:
                    return SPROTO_CB_ERROR
                if r != args.length:
                    return r
                if sub.key == NULL:
                    raise Exception("can't find mainindex (tag=%d) in [%s]a"%(args.mainindex, args.tagname))
                c[<object>(sub.key)] = sub_d
                return 0
            else:
                sub.mainindex_tag = -1
                r = sproto_decode(args.subtype, args.value, args.length, _decode, sub)
                if r < 0:
                    return SPROTO_CB_ERROR
                if r != args.length:
                    return r
                ret = sub_d
        finally:
            PyMem_Free(sub)
    else:
        raise Exception("Invalid type")

    if args.index > 0:
        c.append(ret)
    else:
        if self.mainindex_tag == args.tagid:
            self.key = <PyObject *>ret
        self_d[args.tagname] = ret
    return 0

def decode(stobj, data):
    cdef sproto_type *st = <sproto_type*>get_pointer(stobj, NULL)
    if st == invalid_ptr:
        return None, 0
    cdef char *buf = data
    cdef int size = len(data)
    cdef decode_ud self
    d = {}
    self.data = <PyObject *>d
    self.deep = 0
    self.mainindex_tag = -1
    r = sproto_decode(st, buf, size, _decode, &self)
    if PyErr_Occurred():
        PyErr_Print()
        raise Exception("decode error")
    if r < 0:
        raise Exception("decode error")
    return d, r

cdef object __wrap_st(void *st):
    if st == NULL:
        return None
    return make_capsule(st, NULL, NULL)

cdef void del_sproto(PyObject *obj):
    sp = <sproto*>get_pointer(<object>obj, NULL)
    sproto_release(sp)

def newproto(pbin):
    cdef int size = len(pbin)
    cdef char* pb = pbin
    sp = sproto_create(pb, size)
    #printf("sp: %p\n", sp)
    return make_capsule(sp, NULL, del_sproto)

def query_type(spobj, protoname):
    sp = <sproto*>get_pointer(spobj, NULL)
    #printf("sp: %p\n", <void*>sp)
    st = <sproto_type*>spt(sp, protoname)
    #printf("st: %p\n", <void*>st)
    return make_capsule(<void*>st, NULL, NULL)

def dump(spobj):
    sp = <sproto*>get_pointer(spobj, NULL)
    sproto_dump(sp)

def protocol(spobj, name_or_tag):
    sp = <sproto*>get_pointer(spobj, NULL)
    ret = None
    if isinstance(name_or_tag, int):
        tag = name_or_tag
        name = sproto_protoname(sp, name_or_tag)
        if not name:
            return None
        ret = name
    else:
        assert isinstance(name_or_tag, str)
        tag = sproto_prototag(sp, name_or_tag)
        if tag < 0:
            return None
        ret = tag
        
    req = sproto_protoquery(sp, tag, SPROTO_REQUEST)
    rsp = sproto_protoquery(sp, tag, SPROTO_RESPONSE)
    if rsp == NULL and sproto_protoresponse(sp, tag):
        rsp = invalid_ptr
    return ret, __wrap_st(req), __wrap_st(rsp)

def pack(data):
    cdef char* ptr = data
    cdef int size = len(data)
    cdef maxsz = (size + 2047) / 2048 * 2 + size + 2
    cdef char* buf = <char*>PyMem_Malloc(maxsz)
    try:
        out_sz = sproto_pack(ptr, size, buf, maxsz)
        if out_sz > maxsz:
            return None
        ret = buf[:out_sz]
        return ret
    finally:
        PyMem_Free(buf)

def unpack(data):
    cdef char* ptr = data
    cdef int size = len(data)
    cdef char* buf = <char*>PyMem_Malloc(prealloc)
    cdef r = 0
    try:
        r = sproto_unpack(ptr, size, buf, prealloc)
        if r > prealloc:
            buf = <char*>PyMem_Realloc(buf, r)
            r = sproto_unpack(ptr, size, buf, r)
        if r < 0:
            raise Exception("Invalid unpack stream")
        ret = buf[:r]
        return ret
    finally:
        PyMem_Free(buf)
    
