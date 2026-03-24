async function handler(event) {
    const uri = event.request.uri;
    const match = uri.match(/^\/view\/(MS-DAR-(?:00095|00100|00101|00102|00103|00104|00114|00115))-/);
    if (match) {
        return {
            statusCode: 301,
            statusDescription: "Moved Permanently",
            headers: { location: { value: `/view/${match[1]}/1` } }
        };
    }
    return event.request;
}
