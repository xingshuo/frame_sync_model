# -*- coding: utf-8 -*-
from __future__ import unicode_literals, print_function
from pypeg2 import * 

pypeg2_parse = parse #rename it,for avoiding name conflict
tag = re.compile(r"\d+")
nomeaning = blank, maybe_some(comment_sh), blank
fullname = re.compile(r"[\w+\.]*\w+")

class MainKey(str):
    grammar = "(", word, ")"

class TypeName(object):
    grammar = flag("is_arr", "*"), attr("fullname", fullname)

class Filed(List):
    grammar = attr("filed", word), attr("tag", tag), ":", attr("typename", TypeName),\
            optional(MainKey), nomeaning, endl

class Struct(List):pass
class Type(List):pass

Struct.grammar = "{", nomeaning, attr("fileds", maybe_some([Filed, Type])), "}"
Type.grammar = nomeaning, ".", name(), attr("struct", Struct), nomeaning

class Sub_pro_type(Keyword):
    grammar = Enum(K("request"), K("response"))

class Subprotocol(List):
    grammar = attr("subpro_type", Sub_pro_type), attr("pro_filed", [TypeName, Struct]), nomeaning

class Protocol(List):
    grammar = nomeaning, attr("name", word), attr("tag",tag), "{", nomeaning, attr("fileds", maybe_some(Subprotocol)), "}", nomeaning

class Sproto(List):
    grammar = attr("items", maybe_some([Type, Protocol]))
#====================================================================

builtin_types = {"integer":0, "boolean":1, "string":2}

import re as rawre
def checktype(types, ptype, t):
    if t in builtin_types:
        return t

    fullname = "%s.%s" % (ptype, t)
    if fullname in types:
        return fullname
    else:
        sobj = rawre.search("(.+)\..+$", ptype)
        if sobj:
            return checktype(types, sobj.group(1), t)
        elif t in types:
            return t


def flattypename(r):
    for typename, t in r["type"].iteritems():
        for _, f in enumerate(t):
            ftype = f["typename"]
            fullname = checktype(r["type"], typename, ftype)
            assert fullname != None, "Undefined type %s in type %s" % (ftype, typename)
            f["typename"] = fullname
            if "array" in f and "key" in f:
                pass


class Convert:
    group = {}
    type_dict = {}
    protocol_dict = {}
    protocol_tags = {} #just for easiliy check

    @staticmethod
    def parse(text, name):
        Convert.group = {}
        Convert.type_dict = {}
        Convert.protocol_dict = {}
        Convert.protocol_tags = {}

        obj = pypeg2_parse(text, Sproto)
        for i in obj.items:
            if hasattr(i,"tag"):
                Convert.convert_protocol(i)
            else:
                Convert.convert_type(i)

        Convert.group["type"] = Convert.type_dict
        Convert.group["protocol"] = Convert.protocol_dict

        #import json
        #print(json.dumps(Convert.group, indent=4))
        return Convert.group

    @staticmethod
    def convert_type(obj, parent_name = ""):
        if parent_name != "":
            obj.name = parent_name + "." + obj.name
        type_name = obj.name
        if type_name in Convert.type_dict.keys():
            print("Error:redifine %s\n" % (type_name))
            return False
        Convert.type_dict[type_name] = Convert.convert_struct(obj.struct, type_name)

    @staticmethod
    def convert_struct(obj, name = ""):
        struct = []
        for filed in obj.fileds:
            if type(filed) == Filed:
                filed_typename = filed.typename.fullname
                filed_type = Convert.get_typename(filed_typename)
                filed_info = {}
                filed_info["name"] = filed.filed
                filed_info["tag"] = int(filed.tag)
                filed_info["array"] = filed.typename.is_arr
                filed_info["typename"] = filed_typename
                filed_info["type"] = filed_type
                struct.append(filed_info)
            elif type(filed) == Type:
                Convert.convert_type(filed, name)
        return struct

    @staticmethod
    def convert_protocol(obj):
        if obj.name in Convert.protocol_dict.keys():
            print("Error:redifine protocol %s \n" % (obj.name))
            return
        if obj.tag in Convert.protocol_tags.keys():
            print("Error:redifine protocol tags %d \n" % (obj.tag))
            return
        protocol = {}
        protocol["tag"] = int(obj.tag)
        protocol["name"] = obj.name
        for fi in obj.fileds:
            if type(fi.pro_filed) == TypeName:
                assert fi.pro_filed.is_arr == False, "syntax error at %s.%s" % (obj.name, fi.subpro_type)
                newtype_name = str(''.join(fi.pro_filed.fullname))
                protocol[fi.subpro_type] = newtype_name
            elif type(fi.pro_filed) == Struct:
                newtype_name = obj.name + "." + fi.subpro_type
                Convert.type_dict[newtype_name] = Convert.convert_struct(fi.pro_filed, newtype_name)
                protocol[fi.subpro_type] = newtype_name
           
        Convert.protocol_dict[obj.name] = protocol
        Convert.protocol_tags[obj.tag] = True

    @staticmethod
    def get_typename(name):
        if name in builtin_types:
            return "builtin"
        else:
            return "UserDefine"

# ===============================================================
# export functions
# ===============================================================
__all__ = ["parse", "parse_list", "builtin_types"]

def parse(text, name, check=True):
    build = Convert.parse(text, name)
    if check:
        flattypename(build)
    return build

def parse_list(sproto_list):
    build = {"protocol":{}, "type":{}}
    for v in sproto_list:
        ast = Convert.parse(v[0], v[1])

        #merge type
        for stname, stype in ast["type"].iteritems():
            assert stname not in build["type"], "redifine type %s in %s" % (stname, v[1])
            build["type"][stname] = stype
        #merge protocol
        for spname, sp in ast["protocol"].iteritems():
            assert spname not in build["protocol"], "redifine protocol name %s in %s" %  (spname, v[1])
            for proto in build["protocol"]:
                assert sp["tag"] != build["protocol"][proto]["tag"], "redifine protocol tag %d in %s with %s" % (sp["tag"], proto, spname)
            build["protocol"][spname] = sp

    flattypename(build)
    # checkprotocol(build)
    return build
