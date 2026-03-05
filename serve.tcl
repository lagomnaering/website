# Dev server for Lagom Naering — serves everything from website/ folder
set port 3000

set scriptPath [info script]
if {$scriptPath eq ""} { set scriptPath [file join [pwd] serve.tcl] }
set root [file normalize [file dirname $scriptPath]]

array set mimeTypes {
    .html  "text/html; charset=utf-8"
    .css   "text/css"
    .js    "application/javascript"
    .png   "image/png"
    .jpg   "image/jpeg"
    .jpeg  "image/jpeg"
    .svg   "image/svg+xml"
    .ico   "image/x-icon"
    .webp  "image/webp"
    .gif   "image/gif"
    .pdf   "application/pdf"
}

proc urlDecode {str} {
    set result $str
    while {[regexp {%([0-9A-Fa-f]{2})} $result -> hex]} {
        set result [regsub "%$hex" $result [format "%c" [expr "0x$hex"]]]
    }
    return $result
}

proc handleClient {chan addr remotePort} {
    global root mimeTypes

    fconfigure $chan -translation binary -buffering full

    if {[catch {gets $chan requestLine}]} { catch {close $chan}; return }
    while {[catch {gets $chan hdr}] == 0} {
        if {$hdr eq "\r" || $hdr eq ""} break
    }

    if {![regexp {^GET ([^ ]+)} $requestLine -> rawPath]} {
        catch {close $chan}; return
    }

    set urlPath [urlDecode [regsub {\?.*} $rawPath ""]]
    if {$urlPath eq "/"} { set urlPath "/index.html" }

    set rel      [string trimleft $urlPath "/"]
    set filePath [file normalize [file join $root $rel]]

    # Security: must stay within website/ folder
    set fpNorm [string tolower [file normalize $filePath]]
    set rtNorm [string tolower $root]
    if {[string index $rtNorm end] ne "/"} { append rtNorm "/" }
    if {![string match "${rtNorm}*" $fpNorm]} {
        set b "403 Forbidden"
        puts -nonewline $chan "HTTP/1.1 403 Forbidden\r\nContent-Length: [string length $b]\r\nContent-Type: text/plain\r\n\r\n$b"
        catch {flush $chan; close $chan}; return
    }

    if {[file isfile $filePath]} {
        set ext  [string tolower [file extension $filePath]]
        set mime [expr {[info exists mimeTypes($ext)] ? $mimeTypes($ext) : "application/octet-stream"}]
        set size [file size $filePath]
        puts -nonewline $chan "HTTP/1.1 200 OK\r\nContent-Type: $mime\r\nContent-Length: $size\r\nConnection: close\r\n\r\n"
        flush $chan
        set f [open $filePath rb]
        fconfigure $f -translation binary
        fcopy $f $chan
        close $f
    } else {
        set b "404 Not found: $urlPath"
        puts -nonewline $chan "HTTP/1.1 404 Not Found\r\nContent-Length: [string length $b]\r\nContent-Type: text/plain\r\n\r\n$b"
    }
    catch {flush $chan; close $chan}
}

socket -server handleClient $port
puts "Dev server: http://localhost:$port"
vwait forever
