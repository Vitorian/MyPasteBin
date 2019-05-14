import re

PODTYPES = { 'int64_t': {'size':8, 'pod':True},
            'uint64_t':{'size':8, 'pod':True},
            'int32_t':{'size':4, 'pod':True},
            'uint32_t':{'size':4, 'pod':True},
            'int16_t':{'size':2, 'pod':True},
            'uint16_t':{'size':2, 'pod':True},
            'float':{'size':4, 'pod':True},
            'double':{'size':8, 'pod':True},
            'Price':{'size':8, 'pod':True},
            'Time':{'size':8, 'pod':True},
            'char':{'size':1, 'pod':False} }


def getFieldDecl( field ):
    #print "Field:", field
    if 'Size' in field:
        return "%(Type)s %(Name)s[%(Size)d]; uint16_t %(Name)slen;" % field
    return "%(Type)s %(Name)s" % field

def getFieldArg( field ):
    if 'Size' in field:
        return "const %(Type)s* %(Name)s, uint32_t size" % field
    if field['Type'] in PODTYPES:
        return "%(Type)s %(Name)s" % field
    return "const %(Type)s& %(Name)s" % field

def getFieldReturnType( field ):
    if 'Size' in field:
        return "const %(Type)s*" % field
    if field['Type'] in PODTYPES:
        return "%(Type)s" % field
    return "const %(Type)s&" % field

def getFieldAssign( field ):
    if 'Size' in field:
        return "memcpy( &_msg.%(Name)s, %(Name)s, size ); _msg.%(Name)slen=size;" % field
    return "_msg.%(Name)s = %(Name)s;" % field

def getFieldReference( field ):
    if 'Size' in field:
        return "return &_msg.%(Name)s[0]" % field
    return "return _msg.%(Name)s;" % field

def getFieldSize( field ):
    if 'Size' in field:
        return "(%(Size)d*sizeof(%(Type)s))" % field
    return "(sizeof(%(Type)s))" % field

def getPmapSize( fields ):
    maxtag = max( [int(f['Tag']) for f in fields ] )
    return (maxtag-1)/64 + 1

def getFieldPmap( field ):
    tag = int(field['Tag'])
    pos = (tag-1)/64
    idx = (tag-1)%64
    return "(_pmap[%(pos)d] >> %(idx)d) & 1;" % locals()

def setFieldPmap( field ):
    tag = int(field['Tag'])
    pos = (tag-1)/64
    idx = (tag-1)%64
    return "_pmap[%(pos)d] |=  ( 1UL << %(idx)d );" % locals()

def getSomething( fields ):
    offset = 0
    for field in fields:
        sz = PODTYPES[ field['Type'] ][ 'size' ]
        num = 1
        if 'Size' in field:
            num = field['Size']
        offset += num*sz
    return offset

def getCamel(s):
    #print "[", s, "]"
    return re.sub(r'_([a-zA-Z])', lambda m: m.group(1).upper(), "_"+s)
#return re.sub( '(^[a-z])|(_[a-zA-Z])',lambda m: m.groups()[0].upper(),s)
