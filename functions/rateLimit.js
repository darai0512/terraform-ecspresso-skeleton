async function handler(event) {
    let rate_limit_header = 'normal';
    // rewrite path
    if (event.request.uri === '/redirect' && event.request.headers.host) {
        return {
            statusCode: 302,
            statusDescription: 'Moved Permanently',
            headers: { location: { value: `https://${event.request.headers.host.value}/now` } },
        }
    } else if (!event.request.headers['authorization']) {
        return event.request;
    }
    const decode_str = atob(event.request.headers['authorization'].value.substring(event.request.headers['authorization'].value.indexOf(' ') + 1)); // decode by base64

    if(decode_str.trim()==='hoge'){   rate_limit_header = 'high'      ;}
    else{ rate_limit_header = 'low'    ;}


    event.request.headers['rate-limit'] = {value : rate_limit_header};

    return event.request;
}
