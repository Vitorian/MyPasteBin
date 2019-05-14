\#include <stdint.h>

/** This class is code-generated */

#for $incfile in $Defaults.Includes:
\#include "${incfile}"
#end for

#set $ns = $Defaults.Namespace;
namespace hb
{
    namespace $ns
    {
#for $msgname,$msg in $Messages.iteritems():
#for $field in $msg.Fields:
#if 'Constant' in $field:
        const $field.Type $msgname::$field.Name = $field.Constant;
#end if
#end for
#end for
    }
}
