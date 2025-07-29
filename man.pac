// Настройте адрес и порт вашего прокси здесь
var PROXY_ADDR = "evgn:1997@212.34.144.117:3128";

// Сайты, для которых НЕ применяется прокси (исключения)
var noProxyHosts = [
    "*.antizapret.prostovpn.org",
    "*.docs.google.com"
];

// Сайты, которые нужно проксировать
var proxyHosts = [
    "*.spill.info.gf",
    "antizapret.prostovpn.org",
    "*.whisper.lablab.ai",
    "*.apple.com",
    "*.anythingllm.com",
    "*.chatgpt.com",
    "*.sora.chatgpt.com",
    "*.spotify.com",
    "*.notion.so",
    "*.2ip.ru"
];

// Функция для проверки совпадения хоста с шаблоном (*.example.com)
function shExpMatchHost(host, pattern) {
    if (pattern.startsWith("*.")) {
        var base = pattern.substring(2);
        return host === base || host.endsWith("." + base);
    } else {
        return host === pattern;
    }
}

function FindProxyForURL(url, host) {

    // Проверка исключений — не проксировать эти сайты
    for (var i = 0; i < noProxyHosts.length; i++) {
        if (shExpMatchHost(host, noProxyHosts[i])) {
            return "DIRECT";
        }
    }

    // Если сайт указан в списке прокси — проксировать
    for (var j = 0; j < proxyHosts.length; j++) {
        if (shExpMatchHost(host, proxyHosts[j])) {
            return "PROXY " + PROXY_ADDR;
        }
    }

    // По умолчанию — прямое подключение
    return "DIRECT";
}
