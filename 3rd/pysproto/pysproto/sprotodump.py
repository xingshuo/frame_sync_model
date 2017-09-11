#coding:utf-8
import sprotoparser
import struct 
import sys, argparse, os, codecs

def packbytes(s):
    s = str(s)
    return struct.pack("<I%ds" % len(s), len(s), s) 

def packvalue(v):
    v = (v + 1) * 2
    return struct.pack("<H", v)

def packfield(f):
    strtbl = []
    if f["array"]:
        if f["key"]: #if has no "key" already set to f["key"] = None
            strtbl.append("\6\0")
        else:
            strtbl.append("\5\0")
    else:
        strtbl.append("\4\0")
    strtbl.append("\0\0")
    if f["builtin"] != None:
        strtbl.append(packvalue(f["builtin"]))
        strtbl.append("\1\0")
        strtbl.append(packvalue(f["tag"]))
    else:
        strtbl.append("\1\0")
        strtbl.append(packvalue(f["type"]))
        strtbl.append(packvalue(f["tag"]))
    if f["array"]:
        strtbl.append(packvalue(1))
    if f["key"]:
        strtbl.append(packvalue(f["key"]))
    strtbl.append(packbytes(f["name"]))
    return packbytes("".join(strtbl))

def packtype(name, t, alltypes):
    fields = []
    tmp = {}
    for _, f in enumerate(t):
        tmp["array"] = f["array"]
        tmp["name"] = f["name"]
        tmp["tag"] = f["tag"]
        tname = f["typename"]
        tmp["builtin"] = sprotoparser.builtin_types[tname] if tname in sprotoparser.builtin_types else None
        subtype = None

        if tmp["builtin"] == None:
            assert alltypes[tname], "type %s not exists" % tname
            subtype = alltypes[tname]
            tmp["type"] = subtype["id"]
        else:
            tmp["type"] = None
        if "key" in f:
            tmp["key"] = subtype["fields"][f["key"]["name"]]
            assert tmp["key"], "Invalid map index %d" % f["key"]["name"]
        else:
            tmp["key"] = None
        fields.append(packfield(tmp))
    data = None
    if not fields:
        data = ["\1\0", "\0\0", packbytes(name)]
    else:
        data = ["\2\0", "\0\0", "\0\0", packbytes(name), packbytes("".join(fields))]
    return packbytes("".join(data))

def packproto(name, p, alltypes):
    if "request" in p:
        request = alltypes[p["request"]]
        assert request != None, "Protocol %s request types not found" % (name, p["request"])
        request = request["id"]

    tmp = ["\4\0", "\0\0", packvalue(p["tag"])]
    if "request" not in p and "response" not in p:
        tmp[0] = "\2\0"
    else:
        if "request" in p:
            tmp.append(packvalue(alltypes[p["request"]]["id"]))
        else:
            tmp.append("\1\0")
        if "response" in p:
            tmp.append(packvalue(alltypes[p["response"]]["id"]))
        else:
            tmp[0] = "\3\0"
    tmp.append(packbytes(name))
    return packbytes("".join(tmp))

def packgroup(t, p):
    if not t:
        assert p
        return "\0\0"
    tp = None
    alltypes = {}
    alltype_names = []
    for name in t:
        alltype_names.append(name)
    alltype_names.sort()
    for idx, name in enumerate(alltype_names):
        fields = {}
        for _, type_fields in enumerate(t[name]):
            if type_fields["typename"] in sprotoparser.builtin_types:
                fields[type_fields["name"]] = type_fields["tag"]
        alltypes[name] = { "id":idx, "fields":fields }

    tt = []
    for _, name in enumerate(alltype_names):
        tt.append(packtype(name, t[name], alltypes))

    tt = packbytes("".join(tt))
    if p:
        tmp = []
        for name, tbl in p.iteritems():
            tmp.append(tbl)
            tbl["name"] = name
        tmp = sorted(tmp, key=lambda k: k["tag"])
        tp = []
        for _, tbl in enumerate(tmp):
            tp.append(packproto(tbl["name"], tbl, alltypes))
        tp = packbytes("".join(tp))
    result = None
    if tp == None:
        result = ["\1\0","\0\0",tt]
    else:
        result = ["\2\0","\0\0","\0\0",tt,tp]
    return "".join(result)

def encodeall(r):
    return packgroup(r["type"], r["protocol"])

def parse_ast(ast):
    return encodeall(ast)

def dump(build, outfile):
    data = parse_ast(build)
    f = open(outfile, "wb")
    f.write(data)
    f.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-d", "--directory", dest="src_dir", help="sproto source files")
    parser.add_argument("-f", "--file", dest="src_file", help="sproto single file")
    parser.add_argument("-o", "--out", dest="outfile", default="sproto.spb", help="specific dump binary file")
    parser.add_argument("-v", "--verbose", dest="verbose", action="store_true", help="show more info")
    args = parser.parse_args()

    build = None
    if args.src_file:
        text = codecs.open(args.src_file, encoding="utf-8").read()
        build = sprotoparser.parse(text, os.path.basename(args.src_file))
    else:
        sproto_list = []
        for f in os.listdir(args.src_dir):
            file_path = os.path.join(args.src_dir, f)
            if os.path.isfile(file_path) and f.endswith(".sproto"):
                text = codecs.open(file_path, encoding="utf-8").read()
                sproto_list.append((text, f))

        build = sprotoparser.parse_list(sproto_list)

    if args.verbose == True:
        import json
        print(json.dumps(build, indent=4))
    dump(build, args.outfile)
