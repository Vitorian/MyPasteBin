/*************************************************************************
 * Copyright (C) 2014-2015 Henrique Bucher                               *
 * All rights reserved.                                                  *
 *************************************************************************/
\#pragma once

#from CodeGenUtils import *

#for $incfile in $Defaults.Includes:
\#include "${incfile}"
#end for
\#include "base/Types.h"
\#include "meta/Field.h"
\#include <iostream>
\#include <string>
\#include <cstdint>


namespace hb
{

##=====================================================================
## Start of script, defines namespace
##=====================================================================

#set $df = $Defaults;
#set $ns = $df.Namespace
#set $MyTypes = set( [ k['Name'] for k in $Types ] ) | set( $ClassEnumerations.keys() )

    namespace ${ns}
    {

#for $ttype in $Types:
#set $tname = $ttype.Name;
#if 'Size' in $ttype:
#set $tsize = $ttype.Size;
        typedef $ttype.Type ${tname}[$tsize];
#else
        typedef $ttype.Type ${tname};
#end if
#end for

##for $cname,$ct in $Constants.iteritems():
##if $ct.Type in $MyTypes:
##        static const hb::${ns}::$ct.Type $cname = $ct.Value;
##else
##        static const $ct.Type $cname = $ct.Value;
##end if
##end for

#for $ename,$enum in $Enumerations.iteritems():
        enum $ename {
#for $str in $enum.Strings:
            $str
#end for
        };
#end for

#for $ename,$enum in $ClassEnumerations.iteritems():
#set $etype = $enum.Type
#if $etype in $MyTypes:
#set $etype = "hb::" + $ns + "::" + $etype
#end if
        struct $ename {
            $etype value;
#for $key,$value in $enum.Definitions:
            static constexpr $etype $key = $value;
#end for
            inline operator $etype () const { return value; }
        } __attribute__((packed));
        inline std::ostream& operator << ( std::ostream& oss, const $ename& obj ) {
            oss << $etype (obj.value);
            return oss;
        }
#end for


#set $MyTypes = $MyTypes | set( $Messages.keys() )
#for $priority in range(50):
#for $msgname,$msg in $Messages.iteritems():
#if ($priority==0 and (not 'DisplayOrder' in $msg)) or ($priority==$msg.DisplayOrder)
#set $classname = $msgname;

        // ------------------- $msgname --------------------
        struct ${classname}
        {
            static constexpr const char* NAME ="${classname}";

            template< typename Opaque, class Visitor> inline
            void traverse( Opaque& p, uint32_t rootsize, Visitor* vis ) const
            {
                vis->processMessage( p, *static_cast<const ${classname}*>(this) );
#if len($msg.Nested)>0:
                uint8_t* ptr = (uint8_t*)this;
                ptr += rootsize; //sizeof(*this);
#for $nestmsg in $msg.Nested:
#set $fullname = $nestmsg.FullName
#set $nestname = $nestmsg.Name
#set $dimtype  = $nestmsg.DimType
                {
                    $dimtype * gs = reinterpret_cast<$dimtype*>( ptr );
                    ptr += sizeof( *gs );
##                    std::cout << "NumInGroup:" << int(gs->numInGroup) << " BlockLength:"
##                        << int(gs->blockLength) << std::endl;
                    for( uint32_t j=0; j<gs->numInGroup; ++j ) {
                        vis->processMessage( p, *reinterpret_cast<const hb::$ns::$fullname*>( ptr ) );
                        ptr += gs->blockLength;
                    }
                }
#end for
#end if
            }; // traverse

            template< typename Sink >
            void dump( Sink& sink ) const {
#for $field in $msg.Fields:
#if ('IsGroup' in $field) and ($field.IsGroup):
#continue
#else
#if $field.Name.startswith( "Padding" )
#continue
#end if
#if $field.Type in $Messages:
#set $msg2 = $Messages[ $field.Type ]
#for $field2 in $msg2.Fields:
                sink << hb::meta::field( "${field.Name}.${field2.Name}", ${field.Name}.${field2.Name} );
#end for
#else
                sink << hb::meta::field( "$field.Name", $field.Name );
#end if
#end if
#end for
            }

            template< typename Encoder >
            inline void encode( Encoder& e ) const
            {
                e.init( "${ns}", "${classname}", "", $len($msg.Fields) );
#for $field in $msg.Fields:
#if ('IsGroup' in $field) and ($field.IsGroup):
#continue
#else
#set $count = 0;
#if $field.Name.startswith( "Padding" )
#continue
#end if
#if $field.Type in $Messages:
#set $msg2 = $Messages[ $field.Type ]
#for $field2 in $msg2.Fields:
                e.add( "${field.Name}.${field2.Name}", $count, ${field.Name}.${field2.Name}, 1 );
#set            $count = $count + 1;
#end for
#else
                e.add( "${field.Name}", $count, ${field.Name}, 1 );
#end if
#end if
#end for
            }

            inline void dump( std::ostream& oss ) const {
                oss << "\"$classname\":" << *this;
            }
            friend inline std::ostream& operator << ( std::ostream& oss, const $classname& obj )
            {
                oss << "{ ";
#set $numfields = len($msg.Fields)
#for $fldno in range($numfields)
#set $field = $msg.Fields[$fldno]
#if ('IsGroup' in $field) and ($field.IsGroup):
#continue
#end if
#if $field.Name.startswith( "Padding" )
#continue
#end if
#if $fldno<$numfields-1:
                oss << "\"$field.Name\":" << obj.$field.Name << ",";
#else
                oss << "\"$field.Name\":" << obj.$field.Name;
#end if
#end for
                oss << " } ";
                return oss;
            }; // dump

#for $field in $msg.Fields:
#if ('IsGroup' in $field) and ($field.IsGroup):
#continue
#end if
#set $fldname = $field.Name
#if 'Size' in $field:
#set $fldname = "%s[%d]" % ( $field.Name, $field.Size )
#end if
#set $fldtype = $field.Type
#if $field.Type in $MyTypes:
#set $fldtype = "hb::" + $ns + "::" + $field.Type
#end if
#if 'Constant' in $field:
            static const $fldtype $fldname; // = $field.Constant;
#else
            $fldtype $fldname;
#end if
#end for
        } HB_PACKED;

#end if
#end for
#end for // Priority

        template< typename Opaque, typename Sink >
        void preprocess( Opaque& tm, uint32_t msgid, uint32_t rootsize, uint8_t* data, uint32_t size, Sink& sink ) {
            switch( msgid ) {
#for $msgname,$msg in $Messages.iteritems():
#set $classname = $msgname;
#if 'TemplateId' in $msg:
#if $msg.Parent is None:
            case $msg.TemplateId:
                sink.preprocess( tm, rootsize, *reinterpret_cast<const ${classname}*>(data) );
                break;
#end if
#end if
#end for
            }; // end switch
        }


    }; // end typedef struct/namespace

}; // namespace hb
