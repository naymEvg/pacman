// Настройте адрес и порт вашего прокси здесь
var PROXY_ADDR = "212.34.144.117:3128";

// Сайты, для которых НЕ применяется прокси (исключения)
var noProxyHosts = [
    "*.antizapret.prostovpn.org",
    "*.docs.google.com"
];

// Сайты, которые нужно проксировать
var proxyHosts = [
    "*.whisper.lablab.ai",
    "*.apple.com",
    "*.anythingllm.com", 
    "*.chatgpt.com",
    "*.sora.chatgpt.com",
    "*.spotify.com",
    "*.notion.so",
    "*.2ip.ru", 
    "*.linkedin.com",
    "*.rutracker.me",
    "*.ai.google.dev",
    "*.gemini.google.com",
    "*ai.google.com",
    "*.openai.com",
    "*.indeed.com"
];

// Улучшенная функция для проверки совпадения хоста с шаблоном
function shExpMatchHost(host, pattern) {
    // Приводим к нижнему регистру для корректного сравнения
    host = host.toLowerCase();
    pattern = pattern.toLowerCase();

    if (pattern.startsWith("*.")) {
        var base = pattern.substring(2);
        // Проверяем точное совпадение с базовым доменом или поддомены
        return host === base || host.endsWith("." + base);
    } else {
        // Для паттернов без звездочки проверяем точное совпадение
        return host === pattern;
    }
}

// Альтернативная функция с поддержкой www автоматически
function matchHostWithWWW(host, pattern) {
    host = host.toLowerCase();
    pattern = pattern.toLowerCase();

    if (pattern.startsWith("*.")) {
        var base = pattern.substring(2);
        return host === base || host.endsWith("." + base);
    } else {
        // Для паттернов без звездочки проверяем как точное совпадение, 
        // так и с www префиксом
        return host === pattern || host === ("www." + pattern);
    }
}

function FindProxyForURL(url, host) {

    // Исключения из локальных сетей
    if (isPlainHostName(host) ||
        shExpMatch(host, "localhost") ||
        isInNet(host, "10.0.0.0", "255.0.0.0") ||
        isInNet(host, "172.16.0.0", "255.240.0.0") ||
        isInNet(host, "192.168.0.0", "255.255.0.0") ||
        isInNet(host, "127.0.0.0", "255.255.255.0")) {
        return "DIRECT";
    }

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
