function pause(duration) {
    return new Promise((res) => setTimeout(res, duration * 1000));
}

function backoff(retries, func, delay = 0.5, multiplier = 2) {
    return func().catch((err) => {
        if(retries > 1){
        return pause(delay).then(() => backoff(retries - 1, func, delay * multiplier, multiplier));
        } else {
        Promise.reject(err)
        } 
    });
}

module.exports = {
    pause,
    backoff,
}