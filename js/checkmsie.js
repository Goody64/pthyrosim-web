//=============================================================================
// FILE:        checkmsie.js
// AUTHOR:      Simon X. Han
// DESCRIPTION:
//   Check userAgent for 'msie' and display a warning message for older versions
//   of IE (<9). This is because D3 supports IE9+.
//   This function sits in its own file to ensure it gets loaded without
//   interference from errors in other JavaScript files.
// NOTE:
//   This may not work all the time because browsers have the ability to spoof
//   their userAgent.
//=============================================================================
function checkMSIE() {
    if (navigator.userAgent.match(/msie/i)) {
        $('#non-ie-warn').css("display","block");
    }
}
