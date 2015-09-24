#############################################################################
# <author>Precival Pierre-Richard</author>                                  #
# <date>22-setp-2015</date>                                                 #
# <summary>Replace a string into a files and you get the output.</summary>  #
#############################################################################

#Variables
$original_file = 'path\filename.abc'
$destination_file =  'path\filename.abc.new'

#Instructions
(Get-Content $original_file) | Foreach-Object {
    $_ -replace 'olleH', 'Hello'
    $_ -replace 'dlrow', 'world'
    } | Set-Content $destination_file 
