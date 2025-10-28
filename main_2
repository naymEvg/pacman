var PROXY_ADDR = "212.34.144.117:3128";

var noProxyHosts = [
  "*.antizapret.prostovpn.org",
  "*.docs.google.com"
];

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
  "*.ai.google.com",
  "*.openai.com",
  "*.indeed.com"
];

function shExpMatchHost(host, pattern) {
  host = host.toLowerCase();
  pattern = pattern.toLowerCase();
  if (pattern.startsWith("*.")) {
    var base = pattern.substring(2);
    return host === base || host.endsWith("." + base);
  } else {
    return host === pattern;
  }
}

function FindProxyForURL(url, host) {
  if (isPlainHostName(host) ||
      shExpMatch(host, "localhost") ||
      isInNet(host, "10.0.0.0", "255.0.0.0") ||
      isInNet(host, "172.16.0.0", "255.240.0.0") ||
      isInNet(host, "192.168.0.0", "255.255.0.0") ||
      isInNet(host, "127.0.0.0", "255.255.255.0")) {
    return "DIRECT";
  }

  for (var i = 0; i < noProxyHosts.length; i++) {
    if (shExpMatchHost(host, noProxyHosts[i])) return "DIRECT";
  }

  for (var j = 0; j < proxyHosts.length; j++) {
    if (shExpMatchHost(host, proxyHosts[j])) return "PROXY " + PROXY_ADDR;
  }

  return "DIRECT";
}
