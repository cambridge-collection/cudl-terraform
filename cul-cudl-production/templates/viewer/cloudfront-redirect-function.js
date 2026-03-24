async function handler(event) {
    const uri = event.request.uri;
    const darHookerVolMatch = uri.match(/^\/view\/(MS-DAR-(?:00095|00100|00101|00102|00103|00104|00114|00115))-/);
    if (darHookerVolMatch) {
        return {
            statusCode: 301,
            statusDescription: "Moved Permanently",
            headers: { location: { value: `/view/${darHookerVolMatch[1]}/1` } }
        };
    } else if (/^\/collections\/darwinhooker/.test(uri)) {
        return {
            statusCode: 301,
            statusDescription: "Moved Permanently",
            headers: { location: { value: "/collections/darwin_mss/1" } }
        };
    }
    return event.request;
}
