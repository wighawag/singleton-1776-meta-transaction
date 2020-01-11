function getParamsFromURLHash(url) {
    const obj = {};
    const hash = url.indexOf("#"); // TODO or lastIndexOf ?
    if (hash !== -1) {
        // isolate just the hash value
        url = url.slice(hash + 1);
    }
    if(url.length > 0) {
        const pieces = url.split("&");
        for (let i = 0; i < pieces.length; i++) {
            const parts = pieces[i].split("=");
            if (parts.length < 2) {
                parts.push("");
            }
            const key = decodeURIComponent(parts[0]);
            const value = decodeURIComponent(parts[1]); 
            obj[key] = value;
        }
    }
    return obj;
}

function rebuildLocationHash(hashParams) {
    let reconstructedHash = '';
    const keys = Object.keys(hashParams);
    for(let i = 0; i < keys.length; i++) {
        if (i === 0) {
            reconstructedHash += '#';
        } else {
            reconstructedHash += '&';
        }
        const key = keys[i];
        reconstructedHash += key + '=' + hashParams[key];
    }
    var scrollV, scrollH, loc = window.location;
    if ("replaceState" in history) {
        history.replaceState("", document.title, loc.pathname + loc.search + reconstructedHash);
    } else {
        // Prevent scrolling by storing the page's current scroll offset
        scrollV = document.body.scrollTop;
        scrollH = document.body.scrollLeft;

        loc.hash = "";

        // Restore the scroll offset, should be flicker free
        document.body.scrollTop = scrollV;
        document.body.scrollLeft = scrollH;
    }
}


async function chrome76Detection() {
	if ('storage' in navigator && 'estimate' in navigator.storage) {
		const {usage, quota} = await navigator.storage.estimate();
		if(quota < 120000000)
			return true;
		else
			return false;
	} else {
		return false;
	}
}

function isNewChrome () {
    const pieces = navigator.userAgent.match(/Chrom(?:e|ium)\/([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/);
    if (pieces == null || pieces.length != 5) {
        return undefined;
    }
    major = pieces.map(piece => parseInt(piece, 10))[1];
	if(major >= 76) {
        return true
    }
	return false;
}

function isPrivateWindow() {
    return new Promise(function (resolve, reject) {
        try {
            const isSafari = navigator.vendor && navigator.vendor.indexOf('Apple') > -1 &&
                   navigator.userAgent &&
                   navigator.userAgent.indexOf('CriOS') == -1 &&
                   navigator.userAgent.indexOf('FxiOS') == -1;
                     
            if(isSafari){
                //Safari
                let  e = false;
                if (window.safariIncognito) {
                    e = true;
                } else {
                    try {
                        window.openDatabase(null, null, null, null);
                        window.localStorage.setItem("test", 1)
                        resolve(false);
                    } catch (t) {
                        e = true;
                        resolve(true); 
                    }
                    void !e && (e = !1, window.localStorage.removeItem("test"))
                }
            } else if(navigator.userAgent.includes("Firefox")){
                //Firefox
                var db = indexedDB.open("test");
                db.onerror = function(){resolve(true);};
                db.onsuccess =function(){resolve(false);};
            } else if(navigator.userAgent.includes("Edge") || navigator.userAgent.includes("Trident") || navigator.userAgent.includes("msie")){
                //Edge or IE
                if(!window.indexedDB && (window.PointerEvent || window.MSPointerEvent))
                    resolve(true);
                resolve(false);
            } else {	//Normally ORP or Chrome
                //Other
                if(isNewChrome())
                    resolve(chrome76Detection());
    
                const fs = window.RequestFileSystem || window.webkitRequestFileSystem;
                if (!fs) resolve(null);
                else {
                    fs(window.TEMPORARY, 100, function(fs) {
                        resolve(false);
                    }, function(err) {
                        resolve(true);
                    });
                }
            }
        }
        catch(err) {
            console.error(err);
            resolve(null);
        }
    });
}

function getParamsFromURL(url) {
    var obj = {}, pieces, parts, i;
    var hash = url.indexOf("#");
    if (hash !== -1) {
        url = url.slice(0, hash);
    }
    var question = url.indexOf("?");
    if (question != -1) {
        url = url.slice(question + 1);
        pieces = url.split("&");
        for (i = 0; i < pieces.length; i++) {
            parts = pieces[i].split("=");
            if (parts.length < 2) {
                parts.push("");
            }
            obj[decodeURIComponent(parts[0])] = decodeURIComponent(parts[1]);
        }
    }
    return obj;
}

module.exports = {
    getParamsFromURLHash,
    rebuildLocationHash,
    isPrivateWindow,
    getParamsFromURL,
}