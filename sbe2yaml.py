#!/usr/bin/env python

import os
import sys
import re
import yaml
import pprint

from xml.dom import minidom
from collections import Counter

pp = pprint.PrettyPrinter(indent=4,width=120)

def camelToUnder(name):
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    return re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()

def isInteger(string):
    return re.match("^u*int", string)

def getText(nodelist):
    rc = []
    for node in nodelist.childNodes:
        if node.nodeType == node.TEXT_NODE:
            rc.append(node.data)
    return ''.join(rc)

def getNodes( doc, tagname ):
    for xml in [ x for x in doc.childNodes if x.nodeType==x.ELEMENT_NODE if x.tagName==tagname ]:
        yield xml

if len(sys.argv)<2:
    print "Usage:", sys.argv[0], " <template.xml>"
    sys.exit(1)

############################################################################################
# Processes NS2 messages
############################################################################################
def processMessage( message, parentname=None ):
    name, msgid, descr, length, semtype = [ message.getAttribute(x) for x in
                                            ('name','id','description','blockLength','semanticType') ]
    fullname = '%s_%s' % (parentname, name,) if parentname else name
    fields = []
    nested = []
    groups = []
    tagnum = 0
    size = 0
    revnum = 0
    for field in message.childNodes:
        # Skip text fields
        if not field.nodeType==field.ELEMENT_NODE:
            continue

        # Check if this is a nested message
        isgroup = field.tagName=='group'
        if isgroup:
            fldname,ptype,presence,offset,elsize = [ field.getAttribute(x) for x in
                                                     ('name','dimensionType','presence','offset','blockLength') ]
            elsize = int(elsize)
            #sizeof[ptype] = elsize
            nested.append( field )
            groups.append( { 'Name': fldname, 'FullName': '%s_%s'%(fullname,fldname,),
                             'DimType': ptype } )
        else:
            fldname,ptype,presence,offset = [ field.getAttribute(x) for x in
                                              ('name','type','presence','offset') ]
        isconstant = ptype in constants

        # if computed size is smaller than reported offset, add a reserved field
        if offset:
            offset = int(offset)
            if offset>size:
                revnum += 1
                tagnum += 1
                revsize = offset-size
                size    = offset
                revname = 'Padding%d'%(revnum,)
                fields.append( { 'Name': revname, 'FullName':revname, 'Offset':size,
                                 'Type': 'char', 'Size': revsize, 'Tag': tagnum } )
            elif offset<size:
                print >> sys.stderr, "ERRROR", fullname, "field", fldname, "Offset", offset, "is less than size", size

        # Creates a new field
        tagnum += 1
        if isgroup:
            fields.append( { 'Name': fldname, 'FullName':fldname, 'Type': ptype, 'Tag': tagnum, 'Offset': size, 'IsGroup':isgroup } )
        else:
            fld = { 'Name': fldname, 'FullName':fldname, 'Type': ptype, 'Tag': tagnum, 'Offset': size, 'IsConstant':isconstant }
            if isconstant:
                fld.update( {'Constant': constants[ptype]['Value'] })
            fields.append( fld )

        if (not isgroup) and (not isconstant):
            size += sizeof[ptype]

    # If computed size is smaller than given size, add a reserved field
    blklen = message.getAttribute( 'blockLength' )
    if blklen:
        blklen = int(blklen)
        if blklen>size:
            revnum += 1
            tagnum += 1
            revsize = blklen - size
            size    = blklen
            revname = 'Padding%d'%(revnum,)
            fields.append( { 'Name': revname, 'FullName':revname, 'Type': 'char',
                             'Size': revsize, 'Tag': tagnum } )
        elif blklen<size:
            print >> sys.stderr, 'ERROR: ', fullname, ' message size is',size, 'should be', blklen
    sizeof[name] = size

    # Finalize the message and create a vector of messages for return
    descr= message.getAttribute( 'description' )
    # populate the return vector with all nested messages
    allmsgs = []
    for msg in nested:
        allmsgs.extend( processMessage( msg, fullname ) )
    msg = { 'Name': name,
            'TemplateId': msgid,
            'FullName': fullname,
            'Size': size,
            'AltName': descr,
            'Fields': fields,
            'Nested': groups,
            'NumFields': tagnum,
            'Parent': parentname }
    allmsgs.append( msg )
    return allmsgs


dom = minidom.parse( sys.argv[1] )
sizeof = {'char':1, 'int8':1, 'uint8':1, 'int16':2, 'uint16':2, 'int32':4, 'uint32':4, 'int64':8, 'uint64':8 }

data = {}
constants = {}

for doc in dom.childNodes:
    package,package_id,version,release = [ doc.getAttribute( name ) for name in
                                           ['package','id','version','description'] ]
    #for key,value in doc.attributes.items():
    #    print "   ",key,value

    data[ 'Defaults' ] = { 'Namespace': 'mdp3_v%s' % (version,) ,
                           'Includes': [] }

    #################################################################################################
    # First gather all types from straight typedefs and also from "sets"
    #################################################################################################
    alltypes = { 'uint8': { 'Type': 'uint8_t' },
                 'int8':  { 'Type': 'int8_t'  },
                 'uint16':{ 'Type': 'uint16_t'},
                 'int16': { 'Type': 'int16_t' },
                 'uint32':{ 'Type': 'uint32_t'},
                 'int32': { 'Type': 'int32_t' },
                 'uint64':{ 'Type': 'uint64_t'},
                 'int64': { 'Type': 'int64_t' } }
    types = [ y for y in doc.childNodes if y.nodeType == y.ELEMENT_NODE and y.tagName=='types' ][0]
    for xmltype in getNodes( types, 'type' ):
        name,length,ptype,presence = [ xmltype.getAttribute( x ) for x in ['name','length','primitiveType','presence'] ]

        if length:
            size  = int(length)*sizeof[ptype]
            alltypes[name] = { 'Type': ptype, 'Size':int(length) }
        else:
            size = sizeof[ptype]
            alltypes[name] = { 'Type': ptype }
        if presence=='constant':
            ptext = getText( xmltype )
            alltypes[name]['Constant'] = ptext
            constants[name] = { 'Type':ptype, 'Value':ptext }
            #print "Constant:", name, " Value:", ptext
        sizeof[name] = int(size)
    #print ""
    #print "# Types derived from sets"
    for xmlset in getNodes( types, 'set' ):
        name, ptype = [ xmlset.getAttribute( x ) for x in ('name','encodingType') ]
        sizeof[name] = sizeof[ptype]
        #alltypes[name] = ptype

    #################################################################################################
    # Then order the types by number of references - a type with more references comes first
    #################################################################################################
    types_ordered = []
    nref = Counter( alltypes.keys() )
    for ndummy,ptype in sorted( zip(nref.values(),nref.keys()), reverse=True ):
        tp = alltypes[ptype]
        tp['Name'] = ptype
        types_ordered.append( tp )
    data['Types'] = types_ordered

    #################################################################################################
    # Class Enumerations
    #################################################################################################
    class_enum = {}
    for xmlenum in getNodes( types, 'enum' ):
        ename = xmlenum.getAttribute('name')
        ptype = xmlenum.getAttribute('encodingType')
        values = {}
        for value in getNodes( xmlenum, 'validValue' ):
            vname = value.getAttribute( 'name' )
            vtext = getText( value )
            values[ vname ] = vtext
        sizeof[ename] = sizeof[ptype]
        class_enum[ ename ] = { 'Type': ptype, 'Values': values }

    # Class Enumerations from sets
    for xmlset in getNodes( types, 'set' ):
        ename, ptype = [ xmlset.getAttribute( x ) for x in ('name','encodingType') ]
        values = {}
        for value in getNodes( xmlset, 'choice' ):
            vname = value.getAttribute( 'name' )
            vtext = getText( value )
            vval  = 1 << long(vtext)
            descr = value.getAttribute( 'description' )
            values[ vname ] = vval
        class_enum[ ename ] = { 'Type': ptype, 'Values': values }

    data['ClassEnumerations'] = class_enum


    #################################################################################################
    # Messages from composite types
    #################################################################################################
    messages = {}
    for xmlcomp in getNodes( types, 'composite' ):
        msgname = xmlcomp.getAttribute( 'name' )
        descr= xmlcomp.getAttribute( 'description' )
        tagnum = 0
        size = 0
        revnum = 0
        fields = []
        for xml in getNodes( xmlcomp, 'type' ):
            fldname = xml.getAttribute( 'name' )
            ptype   = xml.getAttribute( 'primitiveType' )
            presence= xml.getAttribute( 'presence' )
            offset  = xml.getAttribute( 'offset' )
            fullname = '%s_%s'%(msgname,fldname)
            if offset:
                offset = int(offset)
                if offset>size:
                    revnum += 1
                    tagnum += 1
                    revsize = offset-size
                    size    = offset
                    revname = 'Padding%d'%(revnum,)
                    fields.append({ 'Name': revname, 'FullName':revname, 'Type': 'char',
                                    'Size': revsize, 'Tag':tagnum })
                elif offset<size:
                    print >> sys.stderr, "ERRROR", msgname, "field", fldname, "Offset", offset, "is less than size", size
            tagnum += 1
            fld = { 'Name': fldname, 'FullName':fullname, 'Type': ptype, 'Tag': tagnum }
            isconstant = presence and (presence=='constant')
            if isconstant:
                ptext = getText( xml )
                fld['Constant'] = ptext
                #print "Constant field",fld
            else:
                size += sizeof[ptype]
            fields.append(fld)

        blklen = xmlcomp.getAttribute( 'blockLength' )
        if blklen:
            blklen = int(blklen)
            if blklen>size:
                revnum += 1
                tagnum += 1
                revsize = blklen - size
                size    = blklen
                revname = 'Padding%d'%revnum,
                fields.append( { 'Name': revname, 'FullName': revname,
                                 'Type': 'char', 'Size': revsize,
                                 'Tag': tagnum } )
        sizeof[msgname] = size
        messages[msgname] = { 'Name': msgname, 'FullName': msgname, 'AltName': descr,
                              'Fields': fields, 'Size': size }

    ns2messages = []
    for m in getNodes( doc, "ns2:message" ):
        ns2messages.extend( processMessage( m ) )
    for message in ns2messages:
        messages[ message['FullName'] ] = message
        sizeof[name] = size

################################################################################
# Order messages by number of references
################################################################################

prio = dict( [ (t,None) for t in messages.keys() ] )
done = False
stepcount = 0
while not done:
    #print >> sys.stderr, "*"*30, "Step ", stepcount
    stepcount += 1
    done = True
    for msgname,msg in messages.iteritems():
        maxprio = 0
        hasprio = True
        ctypes = [ fld['Type'] for fld in msg['Fields'] ]
        if 'Nested' in msg:
            ctypes += [ fld['FullName'] for fld in msg['Nested'] ]
        for fldtype in ctypes:
            #fldtype = fld['Type']
            #print msgname, fldname
            if fldtype in prio:
                thisprio = prio[fldtype]
                if thisprio is None:
                    hasprio = False
                    break
                else:
                    if thisprio>maxprio:
                        maxprio = thisprio

            #else:
                #print >> sys.stderr, fldtype, ' not in prio '
        if hasprio:
            prio[msgname] = maxprio + 1
            msg['DisplayOrder'] = maxprio + 1
            #print >> sys.stderr, "Resolved ", msgname, maxprio + 1
        else:
            done = False
#pp.pprint( messages.values() )
#pp.pprint( prio )
#pp.pprint( [ x for x in messages.values() if not 'FullName' in x ] )
data['Messages'] = messages #sorted( messages.values(), key=lambda x: prio[x['FullName']] )
data['Constants'] = constants
#print "Constants:", constants

yaml.safe_dump( data, sys.stdout, encoding='utf-8', allow_unicode=None )
